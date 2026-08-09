import 'package:flutter/services.dart';

/// Whether this device can surface a persistent notification through
/// Samsung's One UI 7+ Now Bar. There's no public Flutter (or Android)
/// API to query "is Now Bar available" — see the native side
/// (`MainActivity.isNowBarSupported`) for how eligibility is inferred.
class NowBarSupport {
  NowBarSupport._();

  static const _channel = MethodChannel('prayertime/device_info');

  /// Fails closed (`false`) on any platform without this channel — iOS,
  /// desktop, tests — rather than throwing.
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNowBarSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
