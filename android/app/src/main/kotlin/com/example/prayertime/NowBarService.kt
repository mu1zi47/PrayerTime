package com.example.prayertime

import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service behind the "Now Bar" notification (current/next
 * prayer). Built the same way real Now Bar integrations are (see
 * appsfolder/livebridge on GitHub for a working reference): a foreground
 * service posts an ongoing [NotificationCompat] with
 * `setRequestPromotedOngoing(true)` and a short "critical text" — Android
 * 16's public Live Updates API, which is what Samsung's Now Bar actually
 * promotes on. A plain ongoing notification (no promoted-ongoing request)
 * only ever shows as a regular notification, never in the Now Bar itself.
 */
class NowBarService : Service() {
    companion object {
        private const val CHANNEL_ID = "now_bar"
        private const val NOTIFICATION_ID = 999
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_SHORT_TEXT = "shortText"

        /** Starts the service if needed, or updates its notification if already running. */
        fun start(context: Context, title: String, body: String, shortText: String) {
            val intent = Intent(context, NowBarService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
                putExtra(EXTRA_SHORT_TEXT, shortText)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, NowBarService::class.java))
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Намаз"
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""
        val shortText = intent?.getStringExtra(EXTRA_SHORT_TEXT) ?: ""
        val notification = buildNotification(title, body, shortText)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(title: String, body: String, shortText: String): Notification {
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)

        // Live Updates / Now Bar promotion is an Android 16+ (API 36) API.
        // On older OS versions this is simply skipped — the notification
        // still shows normally, just without Now Bar treatment.
        if (Build.VERSION.SDK_INT >= 36 && shortText.isNotEmpty()) {
            builder
                .setShortCriticalText(shortText)
                .setRequestPromotedOngoing(true)
        }

        return builder.build()
    }
}
