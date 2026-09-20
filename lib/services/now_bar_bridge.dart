import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

/// What the Now Bar settings need to know — see [NowBarBridge.status].
class NowBarStatus {
  /// Whether the user wants the notification at all (on by default).
  final bool enabled;

  /// Whether the expanded Now Bar shows all of today's prayers (off by
  /// default) rather than only the current one.
  final bool showSchedule;

  /// A Samsung phone on One UI 8+, where the notification lands in the Now
  /// Bar. Everywhere else it's a plain persistent notification, and the
  /// settings call it that.
  final bool isNowBar;

  /// Notifications allowed for the app and its channel not blocked — without
  /// that, nothing shows no matter what [enabled] says.
  final bool notificationsAllowed;

  /// Android's per-app "Live notifications" promotion. One UI reports it
  /// refused even while the Now Bar shows the notification, so it's only a
  /// fallback for when [liveForAllApps] can't be read.
  final bool promotionAllowed;

  /// One UI's developer switch "Live notifications for all apps", without
  /// which it keeps this app out of the Now Bar. Null when the phone won't
  /// say.
  final bool? liveForAllApps;

  /// Whether developer options have been unlocked on the phone at all —
  /// decides which steps the instructions start from.
  final bool developerOptionsEnabled;

  const NowBarStatus({
    required this.enabled,
    required this.showSchedule,
    required this.isNowBar,
    required this.notificationsAllowed,
    required this.promotionAllowed,
    required this.liveForAllApps,
    required this.developerOptionsEnabled,
  });

  /// The phone has a Now Bar, but its developer switch is what's keeping
  /// the notification out of it. When the switch can't be read, a refused
  /// promotion is the closest sign of the same thing.
  bool get needsDeveloperSwitch =>
      isNowBar && !(liveForAllApps ?? promotionAllowed);

  NowBarStatus copyWith({bool? enabled, bool? showSchedule}) => NowBarStatus(
    enabled: enabled ?? this.enabled,
    showSchedule: showSchedule ?? this.showSchedule,
    isNowBar: isNowBar,
    notificationsAllowed: notificationsAllowed,
    promotionAllowed: promotionAllowed,
    liveForAllApps: liveForAllApps,
    developerOptionsEnabled: developerOptionsEnabled,
  );
}

/// Drives the always-on current-prayer notification, which Samsung's One UI 8
/// shows in the Now Bar.
///
/// The notification itself lives entirely on the Android side
/// (PrayerStatusNotifier.kt) and draws from the same payload as the
/// home-screen widget (see HomeWidgetBridge) — this is only the on/off switch,
/// a few status checks, and the ways into the system settings that matter.
class NowBarBridge {
  const NowBarBridge();

  static const _channel = MethodChannel('uz.mu1zi47.prayertime/now_bar');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Null where there's no such notification (anything but Android).
  Future<NowBarStatus?> status() async {
    if (!_supported) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('status');
      if (raw == null) return null;
      final liveForAllApps = raw['liveForAllApps'];
      return NowBarStatus(
        enabled: raw['enabled'] == true,
        showSchedule: raw['showSchedule'] == true,
        isNowBar: raw['isNowBar'] == true,
        notificationsAllowed: raw['notificationsAllowed'] == true,
        promotionAllowed: raw['promotionAllowed'] == true,
        liveForAllApps: liveForAllApps is bool ? liveForAllApps : null,
        developerOptionsEnabled: raw['developerOptionsEnabled'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setEnabled(bool enabled) => _invoke('setEnabled', enabled);

  Future<void> setShowSchedule(bool show) => _invoke('setShowSchedule', show);

  Future<void> openNotificationSettings() =>
      _invoke('openNotificationSettings');

  Future<void> openDeveloperSettings() => _invoke('openDeveloperSettings');

  Future<void> openDeviceInfo() => _invoke('openDeviceInfo');

  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (_) {
      // Ignored: a settings shortcut isn't worth an error dialog, and the
      // screens re-read the real status when the app comes back.
    }
  }
}
