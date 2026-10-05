import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/services.dart';

/// The phone's own gesture settings, for a control that handles touches
/// itself (the mosque map's zoom strip) and should behave like any other on
/// the phone.
class SystemGesturesBridge {
  const SystemGesturesBridge();

  static const _channel = MethodChannel('uz.mu1zi47.prayertime/gestures');

  /// Replaces the parts of the screen where a swipe from the edge belongs to
  /// the app rather than to the system back gesture (gesture navigation,
  /// Android 10+), in logical pixels; an empty list gives the edges back.
  /// Android honours at most 200dp of each edge.
  Future<void> excludeFromBackGesture(List<Rect> rects) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setExclusionRects', [
        for (final r in rects) [r.left, r.top, r.right, r.bottom],
      ]);
    } catch (_) {
      // An older app build without the channel — swipes on the edge just
      // stay the system's.
    }
  }

  /// How long a touch has to be held to count as a long press — Android's
  /// own setting (Accessibility → "Touch & hold delay"), which every app's
  /// long press follows. Flutter's default elsewhere.
  Future<Duration> longPressTimeout() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return kLongPressTimeout;
    }
    try {
      final ms = await _channel.invokeMethod<int>('longPressTimeout');
      if (ms != null && ms > 0) return Duration(milliseconds: ms);
    } catch (_) {
      // Fall through to the default.
    }
    return kLongPressTimeout;
  }
}
