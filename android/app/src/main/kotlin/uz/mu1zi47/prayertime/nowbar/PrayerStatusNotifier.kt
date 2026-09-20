package uz.mu1zi47.prayertime.nowbar

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Typeface
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.provider.Settings
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StyleSpan
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import org.json.JSONObject
import uz.mu1zi47.prayertime.R
import uz.mu1zi47.prayertime.widget.PrayerWidgetState
import uz.mu1zi47.prayertime.widget.PrayerWidgetStore

/**
 * The always-there "current prayer" notification: the prayer that's on now,
 * a countdown to the end of its window, the next prayer, and a button that
 * logs the current one — the home-screen widget's content, in the shade.
 *
 * It's posted as an Android 16 Live Update (ongoing + promotion requested)
 * and carries One UI's own "ongoing activity" extras, which is what lifts it
 * into the Now Bar on the lock screen and at the top of the shade. Anywhere
 * that doesn't promote it — older Android, other launchers, or the user
 * having switched promotion off — the very same notification is simply a
 * persistent one pinned in the shade.
 *
 * Like the widget, it draws from the payload the app leaves in
 * shared_preferences ([PrayerWidgetState]), so it stays correct with the app
 * fully closed. It's re-rendered only when its content changes (an alarm at
 * the next prayer boundary), when the log changes, and when the user swipes
 * it away — see [PrayerStatusReceiver], which puts it straight back.
 */
object PrayerStatusNotifier {
    private const val CHANNEL_ID = "prayer_status"
    private const val NOTIFICATION_ID = 47_001

    private const val PREFS = "FlutterSharedPreferences"

    /** Owned by this side only; the app toggles it through MainActivity. */
    private const val ENABLED_KEY = "flutter.now_bar_enabled"

    private const val SAMSUNG_NOW_BAR_FEATURE = "com.samsung.feature.nowbar"

    /** Whether the expanded Now Bar lists the whole day; off by default. */
    private const val SCHEDULE_KEY = "flutter.now_bar_schedule"

    fun showsSchedule(context: Context): Boolean =
        prefs(context).getBoolean(SCHEDULE_KEY, false)

    fun setShowSchedule(context: Context, show: Boolean) {
        prefs(context).edit().putBoolean(SCHEDULE_KEY, show).commit()
        refresh(context)
    }

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(ENABLED_KEY, true)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(ENABLED_KEY, enabled).commit()
        refresh(context)
    }

    /**
     * Whether this phone has a Now Bar that other apps' notifications land in.
     * Samsung declares the Now Bar as a system feature, and opened it to every
     * app with One UI 8, which shipped on Android 16 — before that it only
     * took a handful of partner apps.
     */
    fun isNowBarDevice(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA &&
            context.packageManager.hasSystemFeature(SAMSUNG_NOW_BAR_FEATURE)

    /**
     * False when the user has turned "Live notifications" off for this app —
     * the notification still shows, just not in the Now Bar.
     */
    fun canPromote(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA &&
            context.getSystemService(NotificationManager::class.java)
                .canPostPromotedNotifications()

    fun notificationsAllowed(context: Context): Boolean {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return false
        // A channel the user blocked in system settings reads as allowed
        // above, but nothing posted to it is ever shown.
        val channel = manager.getNotificationChannelCompat(CHANNEL_ID)
        return channel == null || channel.importance != NotificationManagerCompat.IMPORTANCE_NONE
    }

    fun refresh(context: Context) {
        val app = context.applicationContext
        if (!isEnabled(app)) {
            cancel(app)
            return
        }

        val state = PrayerWidgetState.load(app, "")
        // Nothing to count down to (fresh install, or a schedule that ran out
        // because the app hasn't been opened in a week) — an empty pinned
        // notification would only be noise. The app brings it back the next
        // time it publishes a schedule.
        if (state !is PrayerWidgetState.Ready) {
            cancel(app)
            return
        }

        val labels = PrayerWidgetStore.payload(app)?.optJSONObject("labels")
        ensureChannel(
            app,
            labels.label("nowBarChannel", app.getString(R.string.now_bar_channel_name)),
        )

        // Only re-armed when there's something showing: once disabled or out
        // of schedule, there is nothing left to wake up for.
        scheduleNextChange(app, state.nextChangeEpochMillis)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        NotificationManagerCompat.from(app).notify(NOTIFICATION_ID, build(app, state, labels))
    }

    private fun build(
        context: Context,
        state: PrayerWidgetState.Ready,
        labels: JSONObject?,
    ): android.app.Notification {
        val prayerOpen = state.currentPrayerKey != null
        val title = headline(state)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_prayer)
            // Fills the icon's circle in the Now Bar and the shade card, the
            // way Samsung's own stopwatch is purple. Not colorized: a
            // colorized notification is never promoted to a Live Update.
            .setColor(context.getColor(look(state).icon))
            .setContentTitle(title)
            // One UI draws the next prayer inside its own card (see
            // samsungExtras) and falls back to this text for a second line
            // under it, which only repeated it — so it's left out there.
            .setContentText(if (isNowBarDevice(context)) null else state.nextLabel)
            // Sits right before the countdown in the header, so it reads as
            // "Ends in · 1:23:45". Between sunrise and Zuhr no prayer is open
            // and the countdown is to Zuhr's start instead.
            .setSubText(
                if (prayerOpen) labels.label("endsIn", "") else labels.label("startsIn", ""),
            )
            // Counts itself down from the window's end, so no per-second or
            // per-minute re-post is needed — only the alarm at that moment.
            .setWhen(state.nextChangeEpochMillis)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setLocalOnly(true)
            // Kept out of the lock screen's notification list, the way One
            // UI keeps the media player out of it: there, the Now Bar
            // already shows it, and One UI doesn't apply this to the Now Bar
            // or the chip. Unlocked, the shade shows it as usual.
            .setVisibility(
                if (isNowBarDevice(context)) {
                    NotificationCompat.VISIBILITY_SECRET
                } else {
                    NotificationCompat.VISIBILITY_PUBLIC
                },
            )
            .setRequestPromotedOngoing(true)
            .addExtras(samsungExtras(context, state, labels))
            .setDeleteIntent(broadcast(context, PrayerStatusReceiver.ACTION_DISMISSED))

        openAppIntent(context)?.let(builder::setContentIntent)

        val dateKey = state.currentDateKey
        val prayerKey = state.currentPrayerKey
        if (dateKey != null && prayerKey != null) {
            // Like the widget's button, it toggles: once logged, it shows
            // as done ("Marked", a filled check) rather than disappearing;
            // tapping it again clears the mark. One UI shows it as an
            // icon-only button (see samsungExtras), so the icon carries the
            // meaning and the label stays for accessibility and the plain
            // notification.
            val actionLabel = if (state.currentMarked) {
                labels.label("marked", "")
            } else {
                labels.label("markDone", "")
            }
            // The icon names this app's package explicitly. The int-only
            // Action.Builder leaves it blank, and SystemUI then looks the
            // resource up in its own package — the icon fails to load, and
            // One UI silently drops an icon-only button with no icon.
            val icon = IconCompat.createWithResource(
                context,
                if (state.currentMarked) R.drawable.ic_now_bar_checked else R.drawable.ic_now_bar_check,
            )
            builder.addAction(
                NotificationCompat.Action.Builder(
                    icon,
                    actionLabel,
                    markPendingIntent(context, dateKey, prayerKey),
                ).build(),
            )
        } else if (isNowBarDevice(context)) {
            // Between sunrise and Zuhr there's nothing to log, but One UI
            // prints the countdown at its full size only on a card that has
            // a button — without one it drops to a small bold line, adrift
            // in a card laid out for more. So there's a button, with an
            // invisible icon (see ic_now_bar_open): it only opens the app,
            // which is what tapping the card does anyway.
            openAppIntent(context)?.let {
                builder.addAction(
                    NotificationCompat.Action.Builder(
                        IconCompat.createWithResource(context, R.drawable.ic_now_bar_open),
                        labels.label("open", ""),
                        it,
                    ).build(),
                )
            }
        }

        // Wherever there's no Now Bar, the whole day goes in the
        // notification's own expanded form instead; collapsed, it stays the
        // standard one-line notification. On Android 16 that custom view
        // keeps it from being promoted to a Live Update (no status-bar chip)
        // — the trade the user makes by leaving this switch on.
        if (showsSchedule(context) && !isNowBarDevice(context)) {
            builder
                .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setCustomBigContentView(scheduleBigView(context, state, title))
        }

        return builder.build()
    }

    /** The plain notification's expanded body: see prayer_schedule_big.xml. */
    private fun scheduleBigView(
        context: Context,
        state: PrayerWidgetState.Ready,
        title: String,
    ) = RemoteViews(context.packageName, R.layout.prayer_schedule_big).apply {
        setTextViewText(R.id.schedule_title, title)
        removeAllViews(R.id.schedule_list)
        for (entry in state.today) {
            val row = RemoteViews(context.packageName, R.layout.prayer_schedule_row)
            row.setTextViewText(R.id.schedule_row_name, entry.name.bold(entry.current))
            row.setTextViewText(R.id.schedule_row_time, entry.time.bold(entry.current))
            if (entry.current) {
                row.setInt(
                    R.id.schedule_row,
                    "setBackgroundResource",
                    R.drawable.prayer_schedule_row_current,
                )
            } else if (entry.passed) {
                row.setFloat(R.id.schedule_row, "setAlpha", PAST_ALPHA)
            }
            if (entry.marked) {
                row.setViewVisibility(R.id.schedule_row_check, View.VISIBLE)
            }
            addView(R.id.schedule_list, row)
        }
    }

    /**
     * One UI's own "ongoing activity" extras — what actually puts a
     * notification into the Now Bar on Samsung phones (together with the
     * `com.samsung.android.support.ongoing_activity` manifest flag). They are
     * undocumented; the shape below follows Samsung Clock's stopwatch, with
     * the second line kept in the collapsed bar the way LiveBridge's is:
     *  - the countdown ("1:23:45") on top, the next prayer ("Fajr · 04:45")
     *    under it, and the mark button;
     *  - the current prayer's name in the status-bar chip;
     *  - optionally, a custom expanded card with today's whole schedule
     *    (see [expandedView]).
     * Ignored everywhere but One UI.
     */
    private fun samsungExtras(
        context: Context,
        state: PrayerWidgetState.Ready,
        labels: JSONObject?,
    ): Bundle {
        val look = look(state)
        // The countdown on top and the next prayer under it, in the one view
        // the collapsed Now Bar shows (see now_bar_chronometer.xml). The
        // second line is just "Fajr · 04:45": the collapsed bar cuts off
        // anything much longer. There's no separate secondary line — the
        // expanded card would show this one twice.
        val countdownBase = SystemClock.elapsedRealtime() + state.untilWindowEndMillis
        val countdown = RemoteViews(context.packageName, R.layout.now_bar_chronometer).apply {
            setChronometerCountDown(R.id.now_bar_chronometer, true)
            setChronometer(R.id.now_bar_chronometer, countdownBase, null, true)
            setTextViewText(R.id.now_bar_next, "${state.nextName} · ${state.nextTime}")
        }
        return Bundle().apply {
            putInt("$SAMSUNG_KEY.style", SAMSUNG_STYLE_NOTIFICATION_AND_NOW_BAR)
            putString("$SAMSUNG_KEY.primaryInfo", state.currentName)
            putString("$SAMSUNG_KEY.nowbarPrimaryInfo", state.currentName)
            // The chip shows just the prayer's name, as text. Not optional:
            // without it the chip would cast the two-line countdown view
            // straight to Chronometer — SystemUI crashed on that again and
            // again. And no `chipExpandedView` of our own: One UI frames an
            // app-built chip in translucent grey (ignoring chipBgColor), and
            // the lock screen card's gradient turns grey along with it.
            putCharSequence("$SAMSUNG_KEY.chipExpandedText", state.currentName)
            putParcelable(
                "$SAMSUNG_KEY.chipIcon",
                Icon.createWithResource(context, R.drawable.ic_now_bar_chip),
            )
            putInt("$SAMSUNG_KEY.chipBgColor", context.getColor(look.chip))
            putInt("$SAMSUNG_KEY.actionType", SAMSUNG_ACTION_ICON_BUTTON)
            putInt("$SAMSUNG_KEY.actionPrimarySet", 1)
            putBoolean("android.showSmallIcon", true)
            putParcelable("$SAMSUNG_KEY.chronometerRemoteView", countdown)
            // The expanded card: the whole day, when the user wants it. Left
            // out, One UI builds its own card from the extras above.
            if (showsSchedule(context)) {
                putParcelable(
                    "$SAMSUNG_KEY.expandedRemoteView",
                    expandedView(context, state, labels, countdownBase),
                )
            }
            putCharSequence("$SAMSUNG_KEY.chronometerRemoteViewTag", CHRONOMETER_TAG)
            putInt("$SAMSUNG_KEY.chronometerRemoteViewPosition", SAMSUNG_POSITION_PRIMARY)
            putInt("$SAMSUNG_KEY.nowbarChronometerPosition", SAMSUNG_POSITION_PRIMARY)
            // The name One UI shows in place of the app's in the card header.
            putCharSequence(
                "android.substName",
                labels.label("nowBarChannel", context.getString(R.string.now_bar_channel_name)),
            )
        }
    }

    /**
     * The expanded card with today's whole schedule (now_bar_expanded.xml).
     * One UI puts it in place of its own expanded card, buttons included, so
     * it carries its own mark button and tap-to-open.
     */
    private fun expandedView(
        context: Context,
        state: PrayerWidgetState.Ready,
        labels: JSONObject?,
        countdownBase: Long,
    ): RemoteViews {
        val prayerOpen = state.currentPrayerKey != null

        return RemoteViews(context.packageName, R.layout.now_bar_expanded).apply {
            openAppIntent(context)?.let { setOnClickPendingIntent(R.id.now_bar_exp_root, it) }

            setTextViewText(R.id.now_bar_exp_title, headline(state))
            setTextViewText(
                R.id.now_bar_exp_countdown_label,
                if (prayerOpen) labels.label("endsIn", "") else labels.label("startsIn", ""),
            )
            setChronometerCountDown(R.id.now_bar_exp_countdown, true)
            setChronometer(R.id.now_bar_exp_countdown, countdownBase, null, true)

            val dateKey = state.currentDateKey
            val prayerKey = state.currentPrayerKey
            if (dateKey != null && prayerKey != null) {
                // A toggle: the same check either way, filled gold once the
                // prayer is logged.
                if (state.currentMarked) {
                    setInt(
                        R.id.now_bar_exp_button,
                        "setBackgroundResource",
                        R.drawable.now_bar_expanded_button_selected,
                    )
                    setInt(
                        R.id.now_bar_exp_button,
                        "setColorFilter",
                        context.getColor(android.R.color.white),
                    )
                }
                setContentDescription(
                    R.id.now_bar_exp_button,
                    if (state.currentMarked) labels.label("marked", "") else labels.label("markDone", ""),
                )
                setOnClickPendingIntent(
                    R.id.now_bar_exp_button,
                    markPendingIntent(context, dateKey, prayerKey),
                )
                setViewVisibility(R.id.now_bar_exp_button, View.VISIBLE)
            } else {
                setViewVisibility(R.id.now_bar_exp_button, View.GONE)
            }

            removeAllViews(R.id.now_bar_exp_list)
            for (entry in state.today) {
                val row = RemoteViews(context.packageName, R.layout.now_bar_expanded_row)
                row.setTextViewText(R.id.now_bar_row_name, entry.name.bold(entry.current))
                row.setTextViewText(R.id.now_bar_row_time, entry.time.bold(entry.current))
                // Colors stay in the layout: resolved there, by SystemUI,
                // they follow the phone's light or dark theme. Picked here
                // they'd follow this process's, which isn't always the same —
                // dark text on the dark card. Past slots are dimmed instead.
                if (entry.current) {
                    row.setInt(
                        R.id.now_bar_row,
                        "setBackgroundResource",
                        R.drawable.now_bar_expanded_row_current,
                    )
                } else if (entry.passed) {
                    row.setFloat(R.id.now_bar_row, "setAlpha", PAST_ALPHA)
                }
                if (entry.marked) {
                    row.setViewVisibility(R.id.now_bar_row_check, View.VISIBLE)
                }
                addView(R.id.now_bar_exp_list, row)
            }
        }
    }

    /**
     * The name the countdown belongs to: the open prayer, whose end it
     * counts to ("Ends in"), or — between sunrise and Zuhr, when it counts
     * to Zuhr's start ("Starts in") — Zuhr. "Sunrise · Starts in 4:04:29"
     * read as if sunrise were still hours away. Whether it's logged is the
     * mark button's to show, not the name's.
     */
    private fun headline(state: PrayerWidgetState.Ready): String =
        if (state.currentPrayerKey == null) state.nextName else state.currentName

    private fun String.bold(bold: Boolean): CharSequence =
        if (!bold) {
            this
        } else {
            SpannableString(this).apply {
                setSpan(StyleSpan(Typeface.BOLD), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
        }

    private fun openAppIntent(context: Context): PendingIntent? =
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            PendingIntent.getActivity(
                context,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

    /** Color resources for one of the app's two themes. */
    private data class Look(val icon: Int, val chip: Int)

    /**
     * The app's bright gold, in the theme chosen *in the app*
     * ([PrayerWidgetState.dark]), not the phone's. It fills the icon's
     * circle, on which One UI always draws the crescent in white. Logging
     * the prayer changes none of it; only the button's icon does.
     */
    private fun look(state: PrayerWidgetState.Ready): Look = if (state.dark) {
        Look(icon = R.color.now_bar_icon_dark, chip = R.color.now_bar_chip_dark)
    } else {
        Look(icon = R.color.now_bar_icon_light, chip = R.color.now_bar_chip_light)
    }

    /**
     * One UI 8's developer switch "Live notifications for all apps"
     * (Settings.Secure `enable_notification_nowbar_test`): until it's on,
     * One UI keeps apps outside Samsung's own allowlist out of the Now Bar.
     * Null when the phone won't let an app read it.
     */
    fun liveNotificationsForAllApps(context: Context): Boolean? = try {
        Settings.Secure.getInt(context.contentResolver, SAMSUNG_ALL_APPS_SWITCH, 0) == 1
    } catch (_: Exception) {
        null
    }

    fun developerOptionsEnabled(context: Context): Boolean = Settings.Global.getInt(
        context.contentResolver,
        Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
        0,
    ) == 1

    /** How far the expanded lists dim the slots already past. */
    private const val PAST_ALPHA = 0.5f

    private const val SAMSUNG_ALL_APPS_SWITCH = "enable_notification_nowbar_test"

    private const val SAMSUNG_KEY = "android.ongoingActivityNoti"
    private const val SAMSUNG_STYLE_NOTIFICATION_AND_NOW_BAR = 1
    private const val SAMSUNG_ACTION_ICON_BUTTON = 0
    private const val SAMSUNG_POSITION_PRIMARY = 1
    private const val CHRONOMETER_TAG = "prayer_countdown_ongoing_activity_chronometer"

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
        alarmManager(context).cancel(broadcast(context, PrayerStatusReceiver.ACTION_REFRESH))
    }

    /**
     * No sound, no vibration, no badge: it's a status line, not an alert.
     * Not IMPORTANCE_MIN — a notification on a min channel is never promoted
     * to a Live Update. Re-created on every render so the channel's name in
     * system settings follows the language picked in the app.
     */
    private fun ensureChannel(context: Context, name: String) {
        val channel = NotificationChannelCompat.Builder(
            CHANNEL_ID,
            NotificationManagerCompat.IMPORTANCE_DEFAULT,
        )
            .setName(name)
            .setSound(null, null)
            .setVibrationEnabled(false)
            .setShowBadge(false)
            .build()
        NotificationManagerCompat.from(context).createNotificationChannel(channel)
    }

    /**
     * Wakes the device on purpose, unlike the widget's alarm: this one is on
     * the lock screen and in the Now Bar, where a countdown running past zero
     * would be seen.
     */
    private fun scheduleNextChange(context: Context, atEpochMillis: Long) {
        val manager = alarmManager(context)
        val pending = broadcast(context, PrayerStatusReceiver.ACTION_REFRESH)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            manager.canScheduleExactAlarms()
        try {
            if (exact) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atEpochMillis, pending)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atEpochMillis, pending)
            }
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atEpochMillis, pending)
        }
    }

    private fun markPendingIntent(
        context: Context,
        dateKey: String,
        prayerKey: String,
    ): PendingIntent {
        val intent = Intent(context, PrayerStatusReceiver::class.java).apply {
            action = PrayerStatusReceiver.ACTION_MARK_DONE
            putExtra(PrayerStatusReceiver.EXTRA_DATE, dateKey)
            putExtra(PrayerStatusReceiver.EXTRA_PRAYER, prayerKey)
            // Same reason as the widget's: extras don't make PendingIntents
            // distinct, so the day/prayer goes in the data URI too.
            data = Uri.parse("prayertime://status-mark/$dateKey/$prayerKey")
        }
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun broadcast(context: Context, action: String) = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, PrayerStatusReceiver::class.java).setAction(action),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun JSONObject?.label(key: String, fallback: String) =
        this?.optString(key)?.takeIf { it.isNotEmpty() } ?: fallback
}
