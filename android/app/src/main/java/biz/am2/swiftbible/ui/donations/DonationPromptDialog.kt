package biz.am2.swiftbible.ui.donations

import android.app.Activity
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import biz.am2.swiftbible.donations.DonationProducts
import biz.am2.swiftbible.donations.DonationService
import biz.am2.swiftbible.ui.AppViewModel
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandGold
import com.android.billingclient.api.ProductDetails

@Composable
fun DonationPromptDialog(
    appVm: AppViewModel,
    activity: Activity,
    onDismiss: () -> Unit,
) {
    val billing = remember { DonationService.get(activity) }
    val products by billing.products.collectAsState()
    val totalCents by appVm.totalDonatedCents.collectAsState(initial = 0)
    var selected by remember { mutableStateOf(DonationProducts.DONATE_5) }
    var showAgainOn by remember { mutableStateOf(true) }

    val recurring = totalCents > 0

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.surface,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp),
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(BrandGold.copy(alpha = 0.18f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.Filled.Stars,
                        contentDescription = null,
                        tint = BrandGold,
                        modifier = Modifier.size(40.dp),
                    )
                }
                Spacer(Modifier.size(14.dp))
                Text(
                    text = if (recurring) "Support SwiftBible Again!" else "Support SwiftBible",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    text = if (recurring) {
                        "Thanks to supporters like you, SwiftBible stays free for everyone. Your continued generosity makes a real difference. 🙏"
                    } else {
                        "SwiftBible is free for everyone — and your generosity keeps it that way. Every gift directly supports the servers and tools that bring Scripture to readers worldwide."
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )

                Spacer(Modifier.size(20.dp))

                Text(
                    text = "Choose an amount",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.fillMaxWidth(),
                )

                Spacer(Modifier.size(10.dp))

                AmountGrid(
                    products = products,
                    selectedId = selected,
                    onSelect = { selected = it },
                )

                Spacer(Modifier.size(8.dp))
                Text(
                    text = "Every gift keeps SwiftBible free for readers worldwide",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    modifier = Modifier.fillMaxWidth(),
                )

                Spacer(Modifier.size(18.dp))

                val product = products.firstOrNull { it.productId == selected }
                Button(
                    onClick = {
                        if (product != null) {
                            billing.launchPurchase(activity, product)
                            onDismiss()
                        }
                    },
                    enabled = product != null,
                    colors = ButtonDefaults.buttonColors(containerColor = BrandAccent),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Icon(Icons.Filled.Favorite, contentDescription = null, tint = Color.White)
                    Spacer(Modifier.size(8.dp))
                    val label = product?.let { formatPrice(it) } ?: "Loading…"
                    Text(
                        text = if (recurring) "Give $label Again! 🎉" else "Give $label",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White,
                    )
                }
                Spacer(Modifier.size(8.dp))
                TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                    Text("Not now")
                }

                Spacer(Modifier.size(12.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = "Show donation reminder pop up",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.weight(1f),
                    )
                    Switch(
                        checked = showAgainOn,
                        onCheckedChange = { showAgainOn = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = MaterialTheme.colorScheme.onPrimary,
                            checkedTrackColor = BrandAccent,
                        ),
                    )
                }

                if (!showAgainOn) {
                    Spacer(Modifier.size(8.dp))
                    TextButton(
                        onClick = { appVm.dismissDonationPrompt(optOut = true) },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text("Don’t show again")
                    }
                }
            }
        }
    }
}

@Composable
private fun AmountGrid(
    products: List<ProductDetails>,
    selectedId: String,
    onSelect: (String) -> Unit,
) {
    val ids = listOf(
        DonationProducts.DONATE_3,
        DonationProducts.DONATE_5,
        DonationProducts.DONATE_10,
        DonationProducts.DONATE_25,
    )
    val rows = ids.chunked(2)
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        rows.forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { id ->
                    val product = products.firstOrNull { it.productId == id }
                    val price = product?.let { formatPrice(it) } ?: defaultPrice(id)
                    AmountTile(
                        price = price,
                        recommended = id == DonationProducts.DONATE_5,
                        selected = selectedId == id,
                        modifier = Modifier.weight(1f),
                        onClick = { onSelect(id) },
                    )
                }
                if (row.size == 1) Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun AmountTile(
    price: String,
    recommended: Boolean,
    selected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    val bg = if (selected) BrandAccent else MaterialTheme.colorScheme.surfaceContainer
    val fg = if (selected) Color.White else MaterialTheme.colorScheme.onSurface
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        color = bg,
        modifier = modifier
            .border(
                width = if (selected) 0.dp else 1.dp,
                color = MaterialTheme.colorScheme.outlineVariant,
                shape = RoundedCornerShape(12.dp),
            ),
    ) {
        Column(
            modifier = Modifier.padding(vertical = 14.dp, horizontal = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = price,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = fg,
            )
            if (recommended) {
                Spacer(Modifier.size(2.dp))
                Text(
                    text = "Most chosen",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (selected) Color.White.copy(alpha = 0.9f) else BrandAccent,
                    fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }
}

private fun formatPrice(p: ProductDetails): String =
    p.oneTimePurchaseOfferDetails?.formattedPrice ?: defaultPrice(p.productId)

private fun defaultPrice(id: String): String = when (id) {
    DonationProducts.DONATE_3 -> "$3.00"
    DonationProducts.DONATE_5 -> "$5.00"
    DonationProducts.DONATE_10 -> "$10.00"
    DonationProducts.DONATE_25 -> "$25.00"
    DonationProducts.DONATE_50 -> "$50.00"
    else -> "$5.00"
}
