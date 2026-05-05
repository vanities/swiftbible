package biz.am2.swiftbible.donations

import android.app.Activity
import android.util.Log
import com.google.android.play.core.review.ReviewManagerFactory
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

object InAppReviewService {
    private const val TAG = "InAppReview"

    suspend fun request(activity: Activity): Boolean = suspendCancellableCoroutine { cont ->
        val manager = ReviewManagerFactory.create(activity)
        manager.requestReviewFlow().addOnCompleteListener { request ->
            if (!request.isSuccessful) {
                Log.w(TAG, "requestReviewFlow failed", request.exception)
                if (cont.isActive) cont.resume(false)
                return@addOnCompleteListener
            }
            val info = request.result
            manager.launchReviewFlow(activity, info).addOnCompleteListener {
                if (cont.isActive) cont.resume(true)
            }
        }
    }
}
