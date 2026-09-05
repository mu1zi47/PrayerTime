package com.example.prayertime.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.example.prayertime.R

/**
 * Home-screen widget: the prayer that's on right now, the one after it, a
 * live countdown, and a button that logs the current prayer as prayed —
 * without opening the app.
 *
 * It draws itself straight from shared_preferences (see [PrayerWidgetStore])
 * rather than from a running Flutter engine, so it stays correct while the
 * app is fully closed. Colors are applied here rather than left to
 * res/values(-night)/, because the widget follows the theme picked *in the
 * app* — see [PrayerWidgetState.dark] and [Palette].
 *
 * Redraws are rare on purpose: the countdown is a self-ticking Chronometer,
 * so the only scheduled wake-up is the moment the *content* changes — the
 * next prayer's time (or the sunrise that closes Fajr's window).
 */
class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        render(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MARK_DONE -> {
                val date = intent.getStringExtra(EXTRA_DATE) ?: return
                val prayer = intent.getStringExtra(EXTRA_PRAYER) ?: return
                PrayerWidgetStore.toggleOnTime(context, date, prayer)
                refresh(context)
            }
            // The app just rewrote the payload or the log — what's on
            // screen may be stale. Sent as an explicit intent from inside
            // this app (or from this widget's own alarm), which is why the
            // receiver can stay unexported.
            ACTION_REFRESH -> refresh(context)
        }
    }

    override fun onDisabled(context: Context) {
        // Last widget removed — nothing left to wake up for.
        alarmManager(context).cancel(refreshPendingIntent(context))
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return

        val state = PrayerWidgetState.load(
            context,
            context.getString(R.string.widget_no_data),
        )
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)

        // Tapping anywhere but the button opens the app, like every stock
        // One UI widget.
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(
                    context,
                    0,
                    it,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        }

        // Two skins for the whole panel, not just the button — the same way
        // One UI's alarm widget goes solid-colored when an alarm is on and
        // drops to a plain panel when none is.
        val marked = (state as? PrayerWidgetState.Ready)?.currentMarked == true
        val palette = Palette(context, state.dark, marked)
        views.setInt(R.id.widget_root, "setBackgroundResource", palette.background)
        views.setTextColor(R.id.widget_current_name, palette.text)
        views.setTextColor(R.id.widget_next_label, palette.kicker)
        views.setTextColor(R.id.widget_countdown, palette.countdown)

        when (state) {
            is PrayerWidgetState.Empty -> {
                views.setTextViewText(R.id.widget_current_name, state.message)
                views.setTextViewText(R.id.widget_next_label, "")
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
                views.setViewVisibility(R.id.widget_mark_button, View.GONE)
            }

            is PrayerWidgetState.Ready -> {
                views.setTextViewText(R.id.widget_current_name, state.currentName)
                views.setTextViewText(R.id.widget_next_label, state.nextLabel)

                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                // Counts down on its own from a point on the elapsed-realtime
                // clock, so no per-minute redraw is needed to keep it honest.
                views.setChronometerCountDown(R.id.widget_countdown, true)
                views.setChronometer(
                    R.id.widget_countdown,
                    SystemClock.elapsedRealtime() + state.untilWindowEndMillis,
                    "%s",
                    true,
                )

                views.setViewVisibility(R.id.widget_mark_button, View.VISIBLE)
                views.setContentDescription(R.id.widget_mark_button, state.markLabel)
                // The icon shows what tapping *does*, not what already
                // happened — the filled panel already says the prayer is
                // logged, so the button offers to undo it.
                views.setImageViewResource(
                    R.id.widget_mark_button,
                    if (state.currentMarked) {
                        R.drawable.ic_widget_clear
                    } else {
                        R.drawable.ic_widget_check
                    },
                )
                views.setInt(
                    R.id.widget_mark_button,
                    "setBackgroundResource",
                    palette.button,
                )
                views.setInt(R.id.widget_mark_button, "setColorFilter", palette.icon)
                views.setOnClickPendingIntent(
                    R.id.widget_mark_button,
                    markPendingIntent(context, state.currentDateKey, state.currentPrayerKey),
                )

                scheduleNextChange(context, state.nextChangeEpochMillis)
            }
        }

        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
    }

    private fun markPendingIntent(
        context: Context,
        dateKey: String,
        prayerKey: String,
    ): PendingIntent {
        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = ACTION_MARK_DONE
            putExtra(EXTRA_DATE, dateKey)
            putExtra(EXTRA_PRAYER, prayerKey)
            // Extras alone don't make two PendingIntents distinct (they're
            // not part of the "same intent" comparison), so the day/prayer
            // goes in the data URI too — otherwise yesterday's Isha button
            // could be reused for today's Fajr.
            data = Uri.parse("prayertime://mark/$dateKey/$prayerKey")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * One alarm, at the moment the widget's text actually becomes wrong.
     * Not a wake-up alarm: there's no one looking at the home screen while
     * the device sleeps, so this fires on the next wake instead of costing
     * a wakelock of its own.
     */
    private fun scheduleNextChange(context: Context, atEpochMillis: Long) {
        val manager = alarmManager(context)
        val pending = refreshPendingIntent(context)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
        try {
            if (exact) {
                manager.setExact(AlarmManager.RTC, atEpochMillis, pending)
            } else {
                manager.set(AlarmManager.RTC, atEpochMillis, pending)
            }
        } catch (_: SecurityException) {
            // Exact-alarm permission revoked between the check and the call —
            // an inexact alarm still refreshes, just a little late.
            manager.set(AlarmManager.RTC, atEpochMillis, pending)
        }
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun refreshPendingIntent(context: Context) = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, PrayerWidgetProvider::class.java).setAction(ACTION_REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /**
     * The two color sets, picked in code rather than by res/values-night, so
     * the app's own Light/Dark/System setting is what decides — see
     * [PrayerWidgetState.dark].
     */
    private class Palette(context: Context, dark: Boolean, marked: Boolean) {
        val background = when {
            marked -> R.drawable.widget_bg_marked
            dark -> R.drawable.widget_bg_dark
            else -> R.drawable.widget_bg_light
        }
        val button = when {
            marked -> R.drawable.widget_button_done
            dark -> R.drawable.widget_button_dark
            else -> R.drawable.widget_button_light
        }
        val text = if (marked) {
            context.getColor(R.color.widget_marked_text)
        } else {
            context.color(dark, R.color.widget_text_dark, R.color.widget_text_light)
        }
        private val textMuted = if (marked) {
            context.getColor(R.color.widget_marked_text_muted)
        } else {
            context.color(
                dark,
                R.color.widget_text_muted_dark,
                R.color.widget_text_muted_light,
            )
        }
        /** The small "next prayer" line under the headline. */
        val kicker = textMuted
        val countdown = if (marked) {
            context.getColor(R.color.widget_marked_text)
        } else {
            context.color(dark, R.color.widget_accent2_dark, R.color.widget_accent2_light)
        }

        /** The button's glyph: bright on the filled panel, dimmed on the plain one. */
        val icon = if (marked) context.getColor(R.color.widget_marked_text) else textMuted

        private fun Context.color(dark: Boolean, darkRes: Int, lightRes: Int) =
            getColor(if (dark) darkRes else lightRes)
    }

    companion object {
        const val ACTION_REFRESH = "com.example.prayertime.widget.REFRESH"
        private const val ACTION_MARK_DONE = "com.example.prayertime.widget.MARK_DONE"
        private const val EXTRA_DATE = "date"
        private const val EXTRA_PRAYER = "prayer"

        /**
         * Redraws every placed widget. Called by the app itself (see
         * MainActivity's method channel) whenever the schedule, the language,
         * the city or the prayer log changes.
         */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, PrayerWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            context.sendBroadcast(
                Intent(context, PrayerWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                },
            )
        }
    }
}
