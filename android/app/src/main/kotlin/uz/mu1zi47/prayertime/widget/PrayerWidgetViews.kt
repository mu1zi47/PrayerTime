package uz.mu1zi47.prayertime.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import uz.mu1zi47.prayertime.R

/**
 * The two shapes a prayer widget can take, and how each one is drawn.
 *
 * Which one a placed widget wears follows its size, not which of the three
 * providers it came from — resize either of them and it turns into the shape
 * that fits, the way the stock clock and weather widgets do. See
 * [PrayerWidgets.Layout] for the breakpoints and [BasePrayerWidgetProvider]
 * for how the host is given all three at once.
 *
 * Everything is drawn from shared_preferences (see [PrayerWidgetStore]), so
 * it stays correct with the app fully closed, and every color is picked here
 * rather than by res/values-night, because a widget follows the theme chosen
 * *in the app* — see [PrayerWidgetState.dark].
 */
object PrayerWidgetViews {

    fun build(
        context: Context,
        provider: Class<out AppWidgetProvider>,
        state: PrayerWidgetState,
        layout: PrayerWidgets.Layout,
    ): RemoteViews = when (layout) {
        PrayerWidgets.Layout.COMPACT -> compact(context, state)
        PrayerWidgets.Layout.WIDE -> wide(context, provider, state)
    }

    /**
     * 2x1: the countdown to the next prayer, with the prayer it counts to
     * named underneath — without that the number alone says nothing.
     *
     * Note it counts to the next prayer's *start*, unlike [wide], whose
     * countdown runs to the end of the current prayer's window (which can be
     * sunrise) — see [PrayerWidgetState.Ready.untilNextPrayerMillis].
     */
    private fun compact(context: Context, state: PrayerWidgetState): RemoteViews {
        val palette = PrayerWidgets.Palette(context, state.dark)
        return RemoteViews(context.packageName, R.layout.prayer_next_widget).apply {
            openApp(context, R.id.next_widget_root)
            setInt(R.id.next_widget_root, "setBackgroundResource", palette.pill)
            setTextColor(R.id.next_widget_countdown, palette.countdown)
            setTextColor(R.id.next_widget_label, palette.muted)

            when (state) {
                is PrayerWidgetState.Empty -> {
                    setTextViewText(R.id.next_widget_label, state.message)
                    setViewVisibility(R.id.next_widget_countdown, View.GONE)
                }

                is PrayerWidgetState.Ready -> {
                    setViewVisibility(R.id.next_widget_countdown, View.VISIBLE)
                    setTextViewText(
                        R.id.next_widget_label,
                        "${state.nextName} · ${state.nextTime}",
                    )
                    countdown(R.id.next_widget_countdown, state.untilNextPrayerMillis)
                }
            }
        }
    }

    /**
     * 4x1: the prayer that's on right now, the one after it, a live
     * countdown, and the button that logs the current prayer as prayed —
     * without opening the app.
     */
    private fun wide(
        context: Context,
        provider: Class<out AppWidgetProvider>,
        state: PrayerWidgetState,
    ): RemoteViews {
        val palette = PrayerWidgets.Palette(context, state.dark)
        return RemoteViews(context.packageName, R.layout.prayer_widget).apply {
            // Tapping anywhere but the button opens the app, like every
            // stock One UI widget.
            openApp(context, R.id.widget_root)
            setInt(R.id.widget_root, "setBackgroundResource", palette.pill)
            setTextColor(R.id.widget_current_name, palette.text)
            setTextColor(R.id.widget_next_label, palette.muted)
            setTextColor(R.id.widget_countdown, palette.countdown)

            when (state) {
                is PrayerWidgetState.Empty -> {
                    setTextViewText(R.id.widget_current_name, state.message)
                    setTextViewText(R.id.widget_next_label, "")
                    setViewVisibility(R.id.widget_countdown, View.GONE)
                    setViewVisibility(R.id.widget_mark_button, View.GONE)
                }

                is PrayerWidgetState.Ready -> {
                    setTextViewText(R.id.widget_current_name, state.currentName)
                    setTextViewText(R.id.widget_next_label, state.nextLabel)
                    setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                    countdown(R.id.widget_countdown, state.untilWindowEndMillis)

                    markButton(context, provider, R.id.widget_mark_button, state, palette)
                }
            }
        }
    }

    /**
     * The button that logs the prayer that's on now, shared by the shapes
     * that carry one. No open prayer (sunrise has closed Fajr's window, Zuhr
     * hasn't arrived) means nothing to log, so it disappears instead of
     * offering to log a Fajr whose time has run out.
     *
     * A toggle: the glyph stays the same and the button fills once logged.
     * Tapping it again clears the mark. Only the button changes when
     * a prayer is logged — the panel around it stays as it is, the way the
     * app marks a prayed prayer (see StatusColors.onTime).
     */
    private fun RemoteViews.markButton(
        context: Context,
        provider: Class<out AppWidgetProvider>,
        viewId: Int,
        state: PrayerWidgetState.Ready,
        palette: PrayerWidgets.Palette,
    ) {
        val dateKey = state.currentDateKey
        val prayerKey = state.currentPrayerKey
        if (dateKey == null || prayerKey == null) {
            setViewVisibility(viewId, View.GONE)
            return
        }
        val marked = state.currentMarked
        setViewVisibility(viewId, View.VISIBLE)
        setContentDescription(viewId, state.markLabel)
        setImageViewResource(
            viewId,
            R.drawable.ic_widget_check,
        )
        setInt(
            viewId,
            "setBackgroundResource",
            when {
                marked -> R.drawable.widget_button_marked
                state.dark -> R.drawable.widget_button_dark
                else -> R.drawable.widget_button_light
            },
        )
        setInt(viewId, "setColorFilter", palette.countdown)
        setOnClickPendingIntent(
            viewId,
            markPendingIntent(context, provider, dateKey, prayerKey),
        )
    }

    /**
     * A Chronometer counting itself down from a point on the elapsed-realtime
     * clock, so nothing has to be redrawn every minute to keep the number
     * honest — see [PrayerWidgets.scheduleNextChange] for the one redraw that
     * is scheduled.
     */
    private fun RemoteViews.countdown(viewId: Int, untilMillis: Long) {
        setChronometerCountDown(viewId, true)
        setChronometer(viewId, SystemClock.elapsedRealtime() + untilMillis, "%s", true)
    }

    private fun RemoteViews.openApp(context: Context, viewId: Int) {
        PrayerWidgets.openAppIntent(context)?.let { setOnClickPendingIntent(viewId, it) }
    }

    private fun markPendingIntent(
        context: Context,
        provider: Class<out AppWidgetProvider>,
        dateKey: String,
        prayerKey: String,
    ): PendingIntent {
        val intent = Intent(context, provider).apply {
            action = PrayerWidgets.ACTION_MARK_DONE
            putExtra(PrayerWidgets.EXTRA_DATE, dateKey)
            putExtra(PrayerWidgets.EXTRA_PRAYER, prayerKey)
            // Extras alone don't make two PendingIntents distinct (they're
            // not part of the "same intent" comparison), so the day/prayer
            // goes in the data URI too — otherwise yesterday's Isha button
            // could be reused for today's Fajr.
            data = Uri.parse("prayertime://mark/${provider.simpleName}/$dateKey/$prayerKey")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
