package uz.mu1zi47.prayertime.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import uz.mu1zi47.prayertime.R

/**
 * What the three home-screen widgets share: opening the app, the single
 * alarm each one sets for the moment its own content goes stale, and the
 * "redraw everything" nudge the app sends after it rewrites the payload or
 * the prayer log.
 *
 * The widgets themselves stay separate providers — the system places, sizes
 * and updates each kind on its own — but none of them has a reason to spell
 * this out again.
 */
object PrayerWidgets {

    /** Every widget kind the app offers. */
    val PROVIDERS = listOf(
        PrayerWidgetProvider::class.java,
        PrayerNextWidgetProvider::class.java,
    )

    const val ACTION_REFRESH = "uz.mu1zi47.prayertime.widget.REFRESH"
    const val ACTION_MARK_DONE = "uz.mu1zi47.prayertime.widget.MARK_DONE"
    const val EXTRA_DATE = "date"
    const val EXTRA_PRAYER = "prayer"

    /** Compact and wide cards vary only with the widget's width. */
    enum class Layout {
        /** Just the countdown — as little as 2x1. */
        COMPACT,

        /** Current prayer, next prayer, countdown, mark button — 4x1. */
        WIDE,

        ;

        companion object {
            const val COMPACT_WIDTH = 110f
            const val WIDE_WIDTH = 250f
            const val SHORT_HEIGHT = 40f

            /**
             * The pre-Android-12 path: the same breakpoints applied to the
             * size the host reports for one placed widget.
             */
            fun forOptions(options: Bundle): Layout {
                val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
                return when {
                    width < WIDE_WIDTH -> COMPACT
                    else -> WIDE
                }
            }
        }
    }

    /** Tapping anywhere on a widget opens the app, like every stock One UI one. */
    fun openAppIntent(context: Context): PendingIntent? =
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

    fun state(context: Context): PrayerWidgetState =
        PrayerWidgetState.load(context, context.getString(R.string.widget_no_data))

    /**
     * One alarm per widget kind, at the moment that widget's text actually
     * becomes wrong — not a wake-up alarm, since no one is looking at the
     * home screen while the device sleeps.
     */
    fun scheduleNextChange(
        context: Context,
        provider: Class<out AppWidgetProvider>,
        atEpochMillis: Long,
    ) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = refreshIntent(context, provider)
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

    fun cancelNextChange(context: Context, provider: Class<out AppWidgetProvider>) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)
            .cancel(refreshIntent(context, provider))
    }

    private fun refreshIntent(
        context: Context,
        provider: Class<out AppWidgetProvider>,
    ) = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, provider).setAction(ACTION_REFRESH),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /**
     * Redraws every placed widget of every kind. Called by the app itself
     * (see MainActivity's method channel) whenever the schedule, the
     * language, the city or the prayer log changes — and by a widget that
     * has just logged a prayer, since the others show that same mark.
     */
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (provider in PROVIDERS) {
            val ids = manager.getAppWidgetIds(ComponentName(context, provider))
            if (ids.isEmpty()) continue
            context.sendBroadcast(
                Intent(context, provider).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                },
            )
        }
    }

    /**
     * The colors every widget shape paints with. Picked here rather than
     * left to res/values-night, because a widget follows the theme chosen
     * *in the app* — see [PrayerWidgetState.dark].
     */
    class Palette(context: Context, dark: Boolean) {
        /** Grouped cards use the app's 24dp corners in every size. */
        val panel = if (dark) R.drawable.widget_panel_dark else R.drawable.widget_panel_light

        /** The same surface in the compact and wide layouts. */
        val pill = if (dark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
        val text = context.color(dark, R.color.widget_text_dark, R.color.widget_text_light)
        val muted = context.color(
            dark,
            R.color.widget_text_muted_dark,
            R.color.widget_text_muted_light,
        )
        val divider = context.color(dark, R.color.widget_divider_dark, R.color.widget_divider_light)
        val countdown =
            context.color(dark, R.color.widget_accent2_dark, R.color.widget_accent2_light)

        /** The check on a logged prayer — the app's "prayed on time" gold. */
        val marked = context.getColor(R.color.widget_marked_bg)

        /** And the ink that reads on it. */
        val markedInk = context.getColor(R.color.widget_marked_text)

        private fun Context.color(dark: Boolean, darkRes: Int, lightRes: Int) =
            getColor(if (dark) darkRes else lightRes)
    }
}
