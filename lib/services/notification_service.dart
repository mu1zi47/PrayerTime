import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
import '../widgets/prayer_icon.dart';

const _azanChannelId = 'azan';
const _notifChannelId = 'prayer_notification';
const _nowBarChannelId = 'now_bar';
const _nowBarChannel = MethodChannel('prayertime/now_bar');

const _prayerOrder = [
  ('fajr', PrayerKind.fajr),
  ('zuhr', PrayerKind.zuhr),
  ('asr', PrayerKind.asr),
  ('maghrib', PrayerKind.maghrib),
  ('isha', PrayerKind.isha),
];

/// Payload carried by a fired notification so the app can open
/// [AzanPlayingScreen] knowing which prayer it was for.
class FiredPrayerNotification {
  final PrayerKind kind;
  final String azanSoundId;

  const FiredPrayerNotification({required this.kind, required this.azanSoundId});
}

/// Thin wrapper around `flutter_local_notifications` for scheduling one
/// notification per upcoming prayer, per day, honouring each prayer's
/// [NotifMode]. See lib/services/README intent in the plan doc for the
/// platform ceilings (Android gets a real lock-screen takeover via
/// full-screen intent; iOS gets a best-effort short custom-sound alert).
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  void Function(FiredPrayerNotification)? onNotificationTapped;

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _azanChannelId,
            'Азан',
            description: 'Полноэкранное оповещение о наступлении времени намаза',
            importance: Importance.max,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            sound: RawResourceAndroidNotificationSound('azan_placeholder'),
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notifChannelId,
            'Уведомления о намазе',
            description: 'Короткое уведомление без полноэкранного азана',
            importance: Importance.high,
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _nowBarChannelId,
            'Now Bar',
            description: 'Текущий и следующий намаз (Samsung One UI 7+)',
            importance: Importance.low,
          ),
        );

    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split('|');
    if (parts.length != 2) return;
    final kind = PrayerKind.values.firstWhere((k) => k.name == parts[0], orElse: () => PrayerKind.fajr);
    onNotificationTapped?.call(FiredPrayerNotification(kind: kind, azanSoundId: parts[1]));
  }

  /// Cancels the whole reserved id pool and re-schedules every
  /// not-yet-passed prayer in [days] according to [notifMode]. Call again
  /// whenever the schedule, notification modes, azan sound, or timezone
  /// (city) change.
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required String azanSoundId,
    required int utcOffsetHours,
  }) async {
    await cancelAll();

    final location = tz.UTC;
    var id = 0;

    for (final day in days) {
      for (final (key, kind) in _prayerOrder) {
        final time = _timeFor(day, key);
        final naive = _combine(day.date, time);
        // City-local wall clock encoded the same way AppState.cityNow is
        // (UTC-flagged DateTime whose fields are the city's local time) —
        // subtract the offset to get a real UTC instant tz can schedule.
        final utcInstant = naive.subtract(Duration(hours: utcOffsetHours));
        final scheduled = tz.TZDateTime.from(utcInstant, location);
        if (scheduled.isBefore(tz.TZDateTime.now(location))) continue;

        final mode = notifMode[key] ?? NotifMode.azan;
        await _scheduleOne(id: id, when: scheduled, kind: kind, mode: mode, azanSoundId: azanSoundId);
        id++;
      }
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required PrayerKind kind,
    required NotifMode mode,
    required String azanSoundId,
  }) async {
    final title = mode == NotifMode.azan ? 'Азан — ${nameForPrayer(kind)}' : 'Наступил намаз ${nameForPrayer(kind)}';
    const body = 'Время совершить намаз';

    final android = switch (mode) {
      NotifMode.azan => AndroidNotificationDetails(
          _azanChannelId,
          'Азан',
          channelDescription: 'Полноэкранное оповещение о наступлении времени намаза',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: const RawResourceAndroidNotificationSound('azan_placeholder'),
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      NotifMode.notification => const AndroidNotificationDetails(
          _notifChannelId,
          'Уведомления о намазе',
          channelDescription: 'Короткое уведомление без полноэкранного азана',
          importance: Importance.high,
          priority: Priority.high,
        ),
      NotifMode.silent => const AndroidNotificationDetails(
          _notifChannelId,
          'Уведомления о намазе',
          channelDescription: 'Короткое уведомление без полноэкранного азана',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
        ),
    };

    final darwin = switch (mode) {
      NotifMode.azan => const DarwinNotificationDetails(
          sound: 'azan_placeholder.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      NotifMode.notification => const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.active),
      NotifMode.silent => const DarwinNotificationDetails(presentSound: false),
    };

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(android: android, iOS: darwin, macOS: darwin),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '${kind.name}|$azanSoundId',
    );
  }

  /// Starts (or updates in place) a real foreground service showing the
  /// "Now Bar" notification — the same mechanism apps like music/navigation
  /// players use to stay "live" while running in the background, which is
  /// what actually qualifies for Samsung's Now Bar surface. A plain ongoing
  /// notification (no backing service) doesn't get that treatment. See
  /// `NowBarService` on the Android side. A no-op on platforms without this
  /// channel — iOS, desktop, tests.
  Future<void> showNowBar({required String title, required String body, required String shortText}) async {
    try {
      await _nowBarChannel.invokeMethod('show', {'title': title, 'body': body, 'shortText': shortText});
    } catch (_) {
      // Ignored — see doc comment above.
    }
  }

  Future<void> cancelNowBar() async {
    try {
      await _nowBarChannel.invokeMethod('cancel');
    } catch (_) {
      // Ignored — see doc comment above.
    }
  }

  /// Whether the user has granted the separate, OS-level "allow promoted
  /// notifications" toggle this app needs for Now Bar promotion — declaring
  /// the manifest permission alone isn't enough. `false` on anything but a
  /// supporting Android build.
  Future<bool> canPostPromotedNotifications() async {
    try {
      final result = await _nowBarChannel.invokeMethod<bool>('canPostPromotedNotifications');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system settings screen for the promoted-notifications
  /// toggle above (falling back to this app's notification settings, then
  /// its app-details page, if the OS build doesn't have that exact screen).
  Future<void> openPromotedNotificationSettings() async {
    try {
      await _nowBarChannel.invokeMethod('openPromotedNotificationSettings');
    } catch (_) {
      // Ignored — see doc comment above.
    }
  }

  Future<void> cancelAll() async {
    // Reserved id pool: 10 upcoming days × 5 prayers = 50 ids max.
    for (var id = 0; id < 50; id++) {
      await _plugin.cancel(id: id);
    }
  }

  String _timeFor(PrayerDay day, String key) => switch (key) {
        'fajr' => day.fajr,
        'zuhr' => day.zuhr,
        'asr' => day.asr,
        'maghrib' => day.maghrib,
        'isha' => day.isha,
        _ => day.fajr,
      };

  DateTime _combine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime.utc(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }
}

/// No-op stand-in used in tests and anywhere real platform channels
/// aren't available — keeps [scheduleForDays] callers simple without
/// littering them with platform checks.
class NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required String azanSoundId,
    required int utcOffsetHours,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> showNowBar({required String title, required String body, required String shortText}) async {}

  @override
  Future<void> cancelNowBar() async {}

  @override
  Future<bool> canPostPromotedNotifications() async => false;

  @override
  Future<void> openPromotedNotificationSettings() async {}
}
