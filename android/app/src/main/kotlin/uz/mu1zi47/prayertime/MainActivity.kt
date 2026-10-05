package uz.mu1zi47.prayertime

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Rect
import android.os.Build
import android.provider.Settings
import android.view.ViewConfiguration
import uz.mu1zi47.prayertime.nowbar.PrayerStatusNotifier
import uz.mu1zi47.prayertime.sounds.NotificationSounds
import uz.mu1zi47.prayertime.widget.PrayerWidgets
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the app tell the home-screen widgets that what they read from
        // shared_preferences has changed — see HomeWidgetBridge on the Dart
        // side. The widget reads that storage itself; this is only the "now
        // redraw" nudge. The current-prayer notification reads the same data,
        // so it's nudged along with it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refreshWidget" -> {
                        PrayerWidgets.refreshAll(applicationContext)
                        PrayerStatusNotifier.refresh(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // The Now Bar / persistent notification settings — see NowBarBridge
        // on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOW_BAR_CHANNEL)
            .setMethodCallHandler { call, result ->
                val context = applicationContext
                when (call.method) {
                    "status" -> result.success(
                        mapOf(
                            "enabled" to PrayerStatusNotifier.isEnabled(context),
                            "showSchedule" to PrayerStatusNotifier.showsSchedule(context),
                            "isNowBar" to PrayerStatusNotifier.isNowBarDevice(context),
                            "notificationsAllowed" to
                                PrayerStatusNotifier.notificationsAllowed(context),
                            "promotionAllowed" to PrayerStatusNotifier.canPromote(context),
                            "liveForAllApps" to
                                PrayerStatusNotifier.liveNotificationsForAllApps(context),
                            "developerOptionsEnabled" to
                                PrayerStatusNotifier.developerOptionsEnabled(context),
                        ),
                    )
                    "setEnabled" -> {
                        PrayerStatusNotifier.setEnabled(context, call.arguments == true)
                        result.success(null)
                    }
                    "setShowSchedule" -> {
                        PrayerStatusNotifier.setShowSchedule(context, call.arguments == true)
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        openAppSettings(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        result.success(null)
                    }
                    // Where the Now Bar's developer switch lives. Falls back
                    // to "About phone" — the way in when developer options
                    // haven't been unlocked yet.
                    "openDeveloperSettings" -> {
                        openSettings(
                            Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS,
                            Settings.ACTION_DEVICE_INFO_SETTINGS,
                        )
                        result.success(null)
                    }
                    "openDeviceInfo" -> {
                        openSettings(Settings.ACTION_DEVICE_INFO_SETTINGS, Settings.ACTION_SETTINGS)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // The phone's sounds, for the notification sound settings — see
        // NotificationSoundsBridge on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOUNDS_CHANNEL)
            .setMethodCallHandler { call, result ->
                val context = applicationContext
                when (call.method) {
                    "list" -> result.success(NotificationSounds.list(context))
                    "defaultTitle" -> result.success(NotificationSounds.defaultTitle(context))
                    "play" -> {
                        NotificationSounds.play(context, call.arguments as String?)
                        result.success(null)
                    }
                    "stop" -> {
                        NotificationSounds.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // The phone's gesture settings for the mosque map's zoom strip: where
        // a swipe from the edge belongs to the app rather than to the system
        // back gesture, and how long a long press is. See
        // SystemGesturesBridge on the Dart side.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GESTURES_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setExclusionRects" -> {
                        setGestureExclusion(call.arguments as? List<*> ?: emptyList<Any>())
                        result.success(null)
                    }
                    "longPressTimeout" -> result.success(ViewConfiguration.getLongPressTimeout())
                    else -> result.notImplemented()
                }
            }
    }

    /// [rects] come as [left, top, right, bottom] in Flutter's logical
    /// pixels; Android wants physical ones.
    private fun setGestureExclusion(rects: List<*>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val density = resources.displayMetrics.density
        window.decorView.systemGestureExclusionRects = rects.mapNotNull { item ->
            val edges = (item as? List<*>)?.map { (it as? Number)?.toDouble() ?: 0.0 }
            if (edges == null || edges.size != 4) return@mapNotNull null
            Rect(
                (edges[0] * density).toInt(),
                (edges[1] * density).toInt(),
                (edges[2] * density).toInt(),
                (edges[3] * density).toInt(),
            )
        }
    }

    // A preview shouldn't keep playing once the app is out of sight.
    override fun onPause() {
        NotificationSounds.stop()
        super.onPause()
    }

    private fun openAppSettings(action: String) {
        val intent = Intent(action).putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            // Nothing else to offer; the sheet still says what to change.
        }
    }

    private fun openSettings(action: String, fallback: String) {
        try {
            startActivity(Intent(action))
        } catch (_: ActivityNotFoundException) {
            try {
                startActivity(Intent(fallback))
            } catch (_: ActivityNotFoundException) {
                // Nothing left to try; the instructions on screen still say
                // where to go.
            }
        }
    }

    companion object {
        private const val WIDGET_CHANNEL = "uz.mu1zi47.prayertime/widget"
        private const val NOW_BAR_CHANNEL = "uz.mu1zi47.prayertime/now_bar"
        private const val SOUNDS_CHANNEL = "uz.mu1zi47.prayertime/sounds"
        private const val GESTURES_CHANNEL = "uz.mu1zi47.prayertime/gestures"
    }
}
