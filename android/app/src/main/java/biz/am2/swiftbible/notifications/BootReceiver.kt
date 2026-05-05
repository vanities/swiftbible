package biz.am2.swiftbible.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import biz.am2.swiftbible.data.UserPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.LOCKED_BOOT_COMPLETED"
        ) return

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val snap = UserPreferences(context.applicationContext).snapshot.first()
                if (snap.reminderEnabled) {
                    DevotionalReminderScheduler.schedule(
                        context.applicationContext,
                        snap.reminderHour,
                        snap.reminderMinute,
                    )
                }
            } finally {
                pendingResult.finish()
            }
        }
    }
}
