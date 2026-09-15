package uz.mu1zi47.prayertime.nowbar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import uz.mu1zi47.prayertime.widget.PrayerWidgetProvider
import uz.mu1zi47.prayertime.widget.PrayerWidgetStore

/**
 * Everything that makes [PrayerStatusNotifier] redraw.
 *
 * Unexported: the system broadcasts below are delivered to it regardless,
 * and the app's own actions are explicit intents — no other app can log a
 * prayer through it.
 */
class PrayerStatusReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_MARK_DONE -> {
                val date = intent.getStringExtra(EXTRA_DATE) ?: return
                val prayer = intent.getStringExtra(EXTRA_PRAYER) ?: return
                PrayerWidgetStore.toggleOnTime(context, date, prayer)
                PrayerStatusNotifier.refresh(context)
                PrayerWidgetProvider.refresh(context)
            }

            // The user swiped it away. Android 14+ lets ongoing notifications
            // be dismissed, but this one is meant to stay until it's turned
            // off in the app — so it's put straight back.
            ACTION_DISMISSED,
            ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            ACTION_QUICKBOOT_POWERON,
            -> PrayerStatusNotifier.refresh(context)
        }
    }

    companion object {
        const val ACTION_REFRESH = "uz.mu1zi47.prayertime.status.REFRESH"
        const val ACTION_DISMISSED = "uz.mu1zi47.prayertime.status.DISMISSED"
        const val ACTION_MARK_DONE = "uz.mu1zi47.prayertime.status.MARK_DONE"
        const val EXTRA_DATE = "date"
        const val EXTRA_PRAYER = "prayer"
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
}
