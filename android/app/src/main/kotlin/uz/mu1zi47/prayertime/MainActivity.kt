package uz.mu1zi47.prayertime

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.Settings
import uz.mu1zi47.prayertime.nowbar.PrayerStatusNotifier
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
    }
}
