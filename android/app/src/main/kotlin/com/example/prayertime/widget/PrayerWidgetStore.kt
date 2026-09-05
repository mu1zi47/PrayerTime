package com.example.prayertime.widget

import android.content.Context
import org.json.JSONObject

/**
 * The widget's half of the data the Flutter app and this widget share.
 *
 * Both sides read and write the *same* shared_preferences file the app
 * already uses (`shared_preferences` on Android is a plain SharedPreferences
 * XML named [PREFS], with every key it owns prefixed `flutter.`) — so the
 * widget needs no running Flutter engine to draw itself or to log a prayer.
 *
 * Two keys matter here:
 *  - [PAYLOAD_KEY], written by the Dart side (see
 *    lib/services/home_widget_bridge.dart): the schedule plus everything
 *    already localized into the language picked *in the app*.
 *  - [LOG_KEY], the prayer log itself, in exactly the format
 *    lib/services/prayer_log_store.dart reads and writes.
 */
object PrayerWidgetStore {
    private const val PREFS = "FlutterSharedPreferences"
    private const val PAYLOAD_KEY = "flutter.widget_payload"
    private const val LOG_KEY = "flutter.prayer_log"

    /** The one status the widget can write — mirrors PrayerLogStatus.onTime. */
    private const val STATUS_ON_TIME = "onTime"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun payload(context: Context): JSONObject? {
        val raw = prefs(context).getString(PAYLOAD_KEY, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun isMarked(context: Context, dateKey: String, prayerKey: String): Boolean =
        log(context)?.optJSONObject(dateKey)?.optString(prayerKey, "")?.isNotEmpty() == true

    /**
     * Flips [prayerKey] on [dateKey] between "prayed on time" and unmarked,
     * the same way tapping an already-chosen option in the app's own log
     * sheet clears it. Returns the state it left behind.
     *
     * Written with `commit()` rather than `apply()`: this runs in a
     * broadcast receiver that may be torn down the moment it returns, and an
     * unflushed write would be lost.
     */
    fun toggleOnTime(context: Context, dateKey: String, prayerKey: String): Boolean {
        val log = log(context) ?: JSONObject()
        val day = log.optJSONObject(dateKey) ?: JSONObject()
        val wasMarked = day.optString(prayerKey, "").isNotEmpty()

        if (wasMarked) day.remove(prayerKey) else day.put(prayerKey, STATUS_ON_TIME)
        if (day.length() == 0) log.remove(dateKey) else log.put(dateKey, day)

        prefs(context).edit().putString(LOG_KEY, log.toString()).commit()
        return !wasMarked
    }

    private fun log(context: Context): JSONObject? {
        val raw = prefs(context).getString(LOG_KEY, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }
}
