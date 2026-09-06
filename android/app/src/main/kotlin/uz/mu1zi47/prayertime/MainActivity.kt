package uz.mu1zi47.prayertime

import uz.mu1zi47.prayertime.widget.PrayerWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the app tell the home-screen widget that what it reads from
        // shared_preferences has changed — see HomeWidgetBridge on the Dart
        // side. The widget reads that storage itself; this is only the "now
        // redraw" nudge.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refreshWidget" -> {
                        PrayerWidgetProvider.refresh(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val WIDGET_CHANNEL = "uz.mu1zi47.prayertime/widget"
    }
}
