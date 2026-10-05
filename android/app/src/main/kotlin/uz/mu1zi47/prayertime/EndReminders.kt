package uz.mu1zi47.prayertime

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import org.json.JSONArray
import org.json.JSONException

/**
 * The "prayer window is closing" reminders, for when a prayer is marked as
 * prayed outside the app — from the Now Bar or the home-screen widget, both
 * of which write the prayer log natively, with no Dart running. The app
 * drops a marked prayer's reminders itself (AppState.setPrayerStatus) and
 * on coming back to the foreground; this does the same on the spot, so they
 * don't go off in the meantime.
 *
 * The reminders are booked by flutter_local_notifications, so cancelling
 * one means undoing what that plugin did: its alarm, the notification if
 * it's already up, and its entry in the plugin's own list of scheduled
 * notifications — which it re-books from after a reboot.
 */
object EndReminders {

    // Mirrors the id scheme in lib/services/notification_service.dart
    // (_notifId, _endReminderSlot) — change one, change both.
    // test/notification_ids_test.dart pins the numbers: zuhr on 2026-10-05
    // is 66408792 to 66408799.
    private const val SLOTS_PER_DAY = 64
    private const val FIRST_END_REMINDER_SLOT = 16
    private const val SLOTS_PER_PRAYER = 8
    private val PRAYER_SLOT = mapOf(
        "fajr" to 1,
        "zuhr" to 2,
        "asr" to 3,
        "maghrib" to 4,
        "isha" to 5,
    )

    // flutter_local_notifications' SharedPreferences file and key for its
    // list of scheduled notifications.
    private const val PLUGIN_CACHE = "scheduled_notifications"

    /** Every id [prayerKey]'s reminders on [dateKey] ("2026-10-05") can have. */
    fun ids(dateKey: String, prayerKey: String): List<Int> {
        val slot = PRAYER_SLOT[prayerKey] ?: return emptyList()
        val parts = dateKey.split("-").mapNotNull { it.toIntOrNull() }
        if (parts.size != 3) return emptyList()
        val (year, month, day) = parts
        val first = (year * 512 + month * 32 + day) * SLOTS_PER_DAY +
            FIRST_END_REMINDER_SLOT + (slot - 1) * SLOTS_PER_PRAYER
        return (0 until SLOTS_PER_PRAYER).map { first + it }
    }

    fun cancel(context: Context, dateKey: String, prayerKey: String) {
        val ids = ids(dateKey, prayerKey)
        if (ids.isEmpty()) return
        val app = context.applicationContext
        val alarms = app.getSystemService(AlarmManager::class.java)
        val shown = NotificationManagerCompat.from(app)
        for (id in ids) {
            // The same PendingIntent the plugin booked the alarm with: its
            // receiver, the notification id as the request code (extras
            // don't count when Android matches one).
            PendingIntent.getBroadcast(
                app,
                id,
                Intent(app, ScheduledNotificationReceiver::class.java),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )?.let {
                alarms?.cancel(it)
                it.cancel()
            }
            shown.cancel(id)
        }
        forgetInPluginCache(app, ids.toSet())
    }

    private fun forgetInPluginCache(context: Context, ids: Set<Int>) {
        val prefs = context.getSharedPreferences(PLUGIN_CACHE, Context.MODE_PRIVATE)
        val raw = prefs.getString(PLUGIN_CACHE, null) ?: return
        val scheduled = try {
            JSONArray(raw)
        } catch (_: JSONException) {
            return
        }
        val kept = JSONArray()
        var removed = false
        for (i in 0 until scheduled.length()) {
            val item = scheduled.opt(i)
            val id = (item as? org.json.JSONObject)?.optInt("id", Int.MIN_VALUE)
            if (id != null && id in ids) removed = true else kept.put(item)
        }
        // commit(), not apply(): this runs in a broadcast receiver that may
        // be torn down the moment it returns.
        if (removed) prefs.edit().putString(PLUGIN_CACHE, kept.toString()).commit()
    }
}
