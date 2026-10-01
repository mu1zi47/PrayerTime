import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

/// Which of the phone's lists a sound comes from — the picker groups them
/// the same way, in this order.
enum SystemSoundKind { notification, ringtone, alarm }

/// One of the phone's own sounds.
class SystemSound {
  final String title;
  final String uri;
  final SystemSoundKind kind;

  const SystemSound({
    required this.title,
    required this.uri,
    required this.kind,
  });
}

/// The phone's sounds for the notification sound settings: what there is,
/// and a way to hear one before picking it. The sounds themselves are set on
/// the notification channels (see NotificationService.channelIdFor) — this
/// is only the catalogue. Android only: iOS doesn't let an app use the
/// system's sounds.
class NotificationSoundsBridge {
  const NotificationSoundsBridge();

  static const _channel = MethodChannel('uz.mu1zi47.prayertime/sounds');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<List<SystemSound>> list() async {
    if (!supported) return const [];
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'list',
      );
      return [
        for (final item in raw ?? const <Map<Object?, Object?>>[])
          if (item['title'] is String && item['uri'] is String)
            SystemSound(
              title: item['title']! as String,
              uri: item['uri']! as String,
              kind: SystemSoundKind.values.firstWhere(
                (k) => k.name == item['kind'],
                orElse: () => SystemSoundKind.notification,
              ),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The name of the sound the phone's default currently is, if it says.
  Future<String?> defaultTitle() async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<String>('defaultTitle');
    } catch (_) {
      return null;
    }
  }

  /// Plays [uri] — the phone's default when null — over any other preview.
  Future<void> play(String? uri) => _invoke('play', uri);

  Future<void> stop() => _invoke('stop');

  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (_) {
      // A preview that doesn't play isn't worth an error.
    }
  }
}
