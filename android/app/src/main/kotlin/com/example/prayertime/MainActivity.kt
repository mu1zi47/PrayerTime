package com.example.prayertime

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deviceInfoChannel = "prayertime/device_info"
    private val nowBarChannel = "prayertime/now_bar"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceInfoChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNowBarSupported" -> result.success(isNowBarSupported())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nowBarChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    val title = call.argument<String>("title") ?: "Намаз"
                    val body = call.argument<String>("body") ?: ""
                    val shortText = call.argument<String>("shortText") ?: ""
                    NowBarService.start(applicationContext, title, body, shortText)
                    result.success(null)
                }
                "cancel" -> {
                    NowBarService.stop(applicationContext)
                    result.success(null)
                }
                "canPostPromotedNotifications" -> result.success(canPostPromotedNotifications())
                "openPromotedNotificationSettings" -> result.success(openPromotedNotificationSettings())
                else -> result.notImplemented()
            }
        }
    }

    // Samsung's Now Bar (One UI's Dynamic-Island-style surface for ongoing
    // notifications) shipped with One UI 7. There's no public API to ask
    // "is Now Bar available" directly, but Samsung ties each One UI major
    // version to one Android release (One UI 7 -> Android 15/API 35,
    // One UI 8 -> Android 16/API 36, and so on), so "Samsung device on
    // API 35+" is a reliable stand-in for "One UI 7 or newer".
    private fun isNowBarSupported(): Boolean {
        val isSamsung = Build.MANUFACTURER.equals("samsung", ignoreCase = true)
        return isSamsung && Build.VERSION.SDK_INT >= 35
    }

    // `NotificationManager.canPostPromotedNotifications()` is new in
    // Android 16 and not yet in every compileSdk's stub jar, so it's called
    // reflectively (same approach used by other Live-Updates apps). Beyond
    // declaring the POST_PROMOTED_NOTIFICATIONS manifest permission, the
    // user separately has to allow this per-app in system settings — this
    // reports whether they already have.
    private fun canPostPromotedNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return try {
            val method = manager.javaClass.getMethod("canPostPromotedNotifications")
            method.invoke(manager) as? Boolean ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun openPromotedNotificationSettings(): Boolean {
        val intent = Intent("android.settings.APP_NOTIFICATION_PROMOTION_SETTINGS").apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        if (launchSettingsIntent(intent)) return true

        val fallback = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        if (launchSettingsIntent(fallback)) return true

        return launchSettingsIntent(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            },
        )
    }

    private fun launchSettingsIntent(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}
