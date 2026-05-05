package biz.am2.swiftbible.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class DevotionalReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        DevotionalReminderScheduler.showNow(context)
    }
}
