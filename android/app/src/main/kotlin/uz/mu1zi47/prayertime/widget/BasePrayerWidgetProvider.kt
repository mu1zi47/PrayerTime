package uz.mu1zi47.prayertime.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import androidx.annotation.RequiresApi
import uz.mu1zi47.prayertime.nowbar.PrayerStatusNotifier

/**
 * What all three prayer widgets are. They differ only in the size the picker
 * places them at — the shape each one draws follows the size it currently
 * has, so resizing one turns it into another, the way the stock clock and
 * weather widgets work.
 *
 * On Android 12 and up all three shapes are handed to the launcher at once
 * (see [responsiveViews]) and it picks per size without waking this process,
 * so a resize is instant. Below that there is no such API, so the shape is
 * chosen here from the size the host reports, and
 * [onAppWidgetOptionsChanged] redraws when that size changes.
 */
abstract class BasePrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        render(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            PrayerWidgets.ACTION_MARK_DONE -> {
                val date = intent.getStringExtra(PrayerWidgets.EXTRA_DATE) ?: return
                val prayer = intent.getStringExtra(PrayerWidgets.EXTRA_PRAYER) ?: return
                PrayerWidgetStore.toggleOnTime(context, date, prayer)
                // Every other widget and the current-prayer notification show
                // that same mark.
                PrayerWidgets.refreshAll(context)
                PrayerStatusNotifier.refresh(context)
            }
            // The app just rewrote the payload or the log — what's on screen
            // may be stale. Sent as an explicit intent from inside this app
            // (or from this widget's own alarm), which is why the receiver
            // can stay unexported.
            PrayerWidgets.ACTION_REFRESH -> {
                val manager = AppWidgetManager.getInstance(context)
                render(
                    context,
                    manager,
                    manager.getAppWidgetIds(ComponentName(context, javaClass)),
                )
            }
        }
    }

    override fun onDisabled(context: Context) {
        // Last widget of this kind removed — nothing left to wake up for.
        PrayerWidgets.cancelNextChange(context, javaClass)
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        if (appWidgetIds.isEmpty()) return

        val state = PrayerWidgets.state(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val views = responsiveViews(context, state)
            appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
        } else {
            for (id in appWidgetIds) {
                val options = appWidgetManager.getAppWidgetOptions(id)
                val layout = PrayerWidgets.Layout.forOptions(options)
                appWidgetManager.updateAppWidget(
                    id,
                    PrayerWidgetViews.build(context, javaClass, state, layout),
                )
            }
        }

        if (state is PrayerWidgetState.Ready) {
            // The first slot of the day to come is the earliest moment any of
            // the three shapes goes stale, so one alarm covers whichever one
            // the launcher happens to be showing.
            PrayerWidgets.scheduleNextChange(context, javaClass, state.nextChangeEpochMillis)
        }
    }

    /**
     * All three shapes in one [RemoteViews]; the launcher draws the largest
     * that fits the cell it has. The sizes are the smallest each shape is
     * legible at, not the size it's placed at.
     */
    @RequiresApi(Build.VERSION_CODES.S)
    private fun responsiveViews(
        context: Context,
        state: PrayerWidgetState,
    ): RemoteViews = RemoteViews(
        mapOf(
            SizeF(PrayerWidgets.Layout.COMPACT_WIDTH, PrayerWidgets.Layout.SHORT_HEIGHT) to
                PrayerWidgetViews.build(context, javaClass, state, PrayerWidgets.Layout.COMPACT),
            SizeF(PrayerWidgets.Layout.WIDE_WIDTH, PrayerWidgets.Layout.SHORT_HEIGHT) to
                PrayerWidgetViews.build(context, javaClass, state, PrayerWidgets.Layout.WIDE),
            SizeF(PrayerWidgets.Layout.WIDE_WIDTH, PrayerWidgets.Layout.TALL_HEIGHT) to
                PrayerWidgetViews.build(context, javaClass, state, PrayerWidgets.Layout.DAY),
        ),
    )
}
