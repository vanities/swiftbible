package biz.am2.swiftbible.donations

import android.app.Activity
import android.content.Context
import android.util.Log
import biz.am2.swiftbible.data.Analytics
import biz.am2.swiftbible.data.AppDatabase
import biz.am2.swiftbible.data.DonationRecord
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class DonationService private constructor(private val appContext: Context) : PurchasesUpdatedListener {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val db = AppDatabase.get(appContext).donationDao()

    private val _products = MutableStateFlow<List<ProductDetails>>(emptyList())
    val products: StateFlow<List<ProductDetails>> = _products.asStateFlow()

    private val _events = MutableSharedFlow<Event>(extraBufferCapacity = 4)
    val events: SharedFlow<Event> = _events.asSharedFlow()

    sealed class Event {
        data class Completed(val record: DonationRecord) : Event()
        data class Failed(val reason: String) : Event()
        object Cancelled : Event()
    }

    private val client: BillingClient = BillingClient.newBuilder(appContext)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build()
        )
        .enableAutoServiceReconnection()
        .build()

    @Volatile private var connected: Boolean = false

    init {
        connect()
    }

    private fun connect() {
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                    connected = true
                    loadProducts()
                    reconcilePending()
                } else {
                    Log.w(TAG, "Billing setup failed: ${result.debugMessage}")
                }
            }

            override fun onBillingServiceDisconnected() {
                connected = false
            }
        })
    }

    private fun loadProducts() {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                DonationProducts.ALL_IDS.map {
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(it)
                        .setProductType(BillingClient.ProductType.INAPP)
                        .build()
                }
            )
            .build()
        client.queryProductDetailsAsync(params) { result, detailsResult ->
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                _products.value = detailsResult.productDetailsList
                    .sortedBy { DonationProducts.amountCents(it.productId) }
                detailsResult.unfetchedProductList.forEach {
                    Log.w(TAG, "queryProductDetails: unfetched ${it.productId} status=${it.statusCode}")
                }
            } else {
                Log.w(TAG, "queryProductDetails: ${result.debugMessage}")
            }
        }
    }

    private fun reconcilePending() {
        val params = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()
        client.queryPurchasesAsync(params) { result, purchases ->
            if (result.responseCode != BillingClient.BillingResponseCode.OK) return@queryPurchasesAsync
            for (p in purchases) scope.launch { handlePurchase(p) }
        }
    }

    fun launchPurchase(activity: Activity, product: ProductDetails): Boolean {
        if (!connected) return false
        val params = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(product)
                        .build()
                )
            )
            .build()
        val result = client.launchBillingFlow(activity, params)
        val ok = result.responseCode == BillingClient.BillingResponseCode.OK
        if (ok) {
            Analytics.capture(
                Analytics.Event.DonationPaymentSheetShown,
                mapOf(
                    "product_id" to product.productId,
                    "amount_cents" to DonationProducts.amountCents(product.productId),
                ),
            )
        }
        return ok
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { p -> scope.launch { handlePurchase(p) } }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                Analytics.capture(Analytics.Event.DonationCancelled)
                scope.launch { _events.emit(Event.Cancelled) }
            }
            else -> {
                Analytics.capture(
                    Analytics.Event.DonationFailed,
                    mapOf(
                        "code" to result.responseCode,
                        "message" to result.debugMessage.ifBlank { "Purchase failed" },
                    ),
                )
                scope.launch {
                    _events.emit(Event.Failed(result.debugMessage.ifBlank { "Purchase failed" }))
                }
            }
        }
    }

    private suspend fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) return
        val productId = purchase.products.firstOrNull() ?: return
        val record = DonationRecord(
            purchaseToken = purchase.purchaseToken,
            productId = productId,
            amountCents = DonationProducts.amountCents(productId),
            currency = "USD",
            purchaseTime = purchase.purchaseTime,
        )
        db.insert(record)

        val consumed = consume(purchase.purchaseToken)
        if (!consumed) acknowledge(purchase.purchaseToken)

        Analytics.capture(
            Analytics.Event.DonationCompleted,
            mapOf(
                "product_id" to productId,
                "amount_cents" to record.amountCents,
                "currency" to record.currency,
            ),
        )
        _events.emit(Event.Completed(record))
    }

    private suspend fun consume(token: String): Boolean = suspendCancellableCoroutine { cont ->
        val params = ConsumeParams.newBuilder().setPurchaseToken(token).build()
        client.consumeAsync(params) { result, _ ->
            cont.resume(result.responseCode == BillingClient.BillingResponseCode.OK)
        }
    }

    private suspend fun acknowledge(token: String): Boolean = suspendCancellableCoroutine { cont ->
        val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()
        client.acknowledgePurchase(params) { result ->
            cont.resume(result.responseCode == BillingClient.BillingResponseCode.OK)
        }
    }

    companion object {
        private const val TAG = "DonationService"

        @Volatile private var instance: DonationService? = null
        fun get(context: Context): DonationService = instance ?: synchronized(this) {
            instance ?: DonationService(context.applicationContext).also { instance = it }
        }
    }
}
