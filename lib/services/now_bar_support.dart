import 'package:flutter/services.dart';

class NowBarSupport {
  NowBarSupport._();

  static const _channel = MethodChannel('prayertime/device_info');

  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNowBarSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
