import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/timezone_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../widgets/prayer_icon.dart';
import 'prayer_log_store.dart';

const _notifChannelId = 'prayer_notification';

// The "Прочитал"/"Done" action button on a prayer-time notification — see
// NotificationService._onResponse and _notificationBackgroundHandler.
const _markDoneActionId = 'mark_done';

/// How long before a prayer's window closes the "you haven't marked this one
/// yet" nudge fires — see [NotificationService.scheduleForDays].
const kPrayerEndingReminderLead = Duration(minutes: 30);

const _prayerOrder = [
  ('fajr', PrayerKind.fajr),
  ('zuhr', PrayerKind.zuhr),
  ('asr', PrayerKind.asr),
  ('maghrib', PrayerKind.maghrib),
  ('isha', PrayerKind.isha),
];

// Every prayer-day owns a fixed block of ids, one per slot below, so a
// single scheduled notification can be addressed (and cancelled) on its own
// later — see NotificationService.cancelPrayerEndReminder, which is how
// marking a prayer prayed silences its pending reminder without rebuilding
// the whole schedule.
const _slotsPerDay = 16;
const _slotEveningReminder = 15;

int _prayerSlot(String key) => switch (key) {
  'tahajjud' => 0,
  'fajr' => 1,
  'zuhr' => 2,
  'asr' => 3,
  'maghrib' => 4,
  'isha' => 5,
  _ => 0,
};

/// The id of the notification in [slot] on [date]'s block. The date's parts
/// are packed rather than turned into a day count, so daylight-saving
/// shifts can't quietly collapse two neighbouring days onto one id.
int _notifId(DateTime date, int slot) =>
    ((date.year * 512 + date.month * 32 + date.day) * _slotsPerDay) + slot;

/// Runs in a fresh, isolated Dart isolate with no access to any running
/// AppState — the app process was fully terminated when the action fired.
/// Writes straight to shared_preferences via [PrayerLogStore], the same
/// on-disk format AppState itself reads/writes.
@pragma('vm:entry-point')
void _notificationBackgroundHandler(NotificationResponse response) {
  if (response.actionId != _markDoneActionId) return;
  final parsed = _parseMarkDonePayload(response.payload);
  if (parsed == null) return;
  final (dateKey, prayerKey) = parsed;
  PrayerLogStore.markOnTime(dateKey, prayerKey);
  // Same reason AppState.setPrayerStatus does this — a prayer marked from
  // the notification itself shouldn't still get nagged about later. Best
  // effort: this isolate may not have a live plugin channel to cancel
  // through, in which case the reminder just fires as scheduled.
  FlutterLocalNotificationsPlugin()
      .cancel(
        id: NotificationService.prayerEndReminderId(
          DateTime.parse(dateKey),
          prayerKey,
        ),
      )
      .catchError((_) {});
}

(String, String)? _parseMarkDonePayload(String? payload) {
  if (payload == null) return null;
  final parts = payload.split('|');
  if (parts.length != 2) return null;
  return (parts[0], parts[1]);
}

/// One notification the schedule says should exist, before anything has
/// been handed to the platform — see [NotificationService.scheduleForDays],
/// which builds the whole list first and only then books it, nearest first
/// and in small batches.
class _PlannedNotification {
  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;
  final NotifMode mode;
  final String? payload;
  final String? actionLabel;

  const _PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.mode,
    required this.payload,
    required this.actionLabel,
  });
}

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Bumped by every [scheduleForDays] call so the batches still trickling
  /// out from the previous one stop instead of racing the new schedule.
  int _generation = 0;

  /// Set by AppState during init — lets a "Прочитал"/"Done" notification
  /// action update the already-running app (in-memory state + disk) instead
  /// of only the disk copy that [_notificationBackgroundHandler] writes to
  /// when the process isn't alive to receive this callback at all.
  Future<void> Function(DateTime date, String prayerKey)? onMarkDone;

  Future<void> init() async {
    ensureTimeZonesInitialized();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse:
          _notificationBackgroundHandler,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notifChannelId,
            'Уведомления о намазе',
            description: 'Уведомление о наступлении времени намаза',
            importance: Importance.high,
          ),
        );
  }

  /// Called from the first-run setup flow (see OnboardingScreen), not from
  /// [init] — asking on the very first frame, before anything has explained
  /// what the notifications are for, is how permission prompts get denied.
  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Just the notification permission, without the exact-alarm settings
  /// detour [requestPermissions] takes — for turning on the Now Bar
  /// notification, which needs nothing else.
  Future<void> requestNotificationsPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// [prayerLog] is AppState's own log, in the same shape it keeps it —
  /// a prayer already marked there gets no "window is closing" reminder,
  /// since there's nothing left to remind about (see
  /// [cancelPrayerEndReminder] for the same thing happening after the fact,
  /// when a prayer is marked while its reminder is already scheduled).
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required Duration utcOffset,
    required AppLocale locale,
    required bool quietHoursEnabled,
    bool includeTahajjud = false,
    Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
  }) async {
    final generation = ++_generation;
    final t = lookupAppLocalizations(locale.localeValue);
    final location = tz.UTC;
    final planned = <_PlannedNotification>[];

    // Tahajjud sorts before Fajr — it's the last third of the *same*
    // record's night, so it always falls earlier in the clock than that
    // record's own Fajr (see PrayerDay.tahajjud).
    final order = [
      if (includeTahajjud) ('tahajjud', PrayerKind.tahajjud),
      ..._prayerOrder,
    ];

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final dayKey = PrayerLogStore.dateKey(day.date);
      final dayLog = prayerLog[dayKey] ?? const <String, PrayerLogStatus>{};

      for (final (key, kind) in order) {
        final mode = notifMode[key] ?? NotifMode.notification;
        if (mode == NotifMode.off) continue;
        final naive = _combine(day.date, _timeFor(day, key));
        final scheduled = _toTz(naive, utcOffset, location);
        if (scheduled.isBefore(tz.TZDateTime.now(location))) continue;

        // Tahajjud isn't one of the five prayers tracked on the prayer log,
        // so it gets no mark-done action — there's nowhere for that mark to
        // show up.
        final payload = key == 'tahajjud' ? null : '$dayKey|$key';
        planned.add(
          _PlannedNotification(
            id: _notifId(day.date, _prayerSlot(key)),
            when: scheduled,
            title: t.notifPlainTitle(nameForPrayer(t, kind)),
            body: t.notifBody,
            mode: _effectiveMode(mode, naive.hour, quietHoursEnabled),
            payload: payload,
            actionLabel: t.notifMarkDoneAction,
          ),
        );
      }

      // A last call before each prayer's window closes, for a prayer that
      // still isn't marked as prayed. The window ends where the next one
      // starts (Fajr's at sunrise, Isha's at the following day's Fajr), so
      // the very last day on hand gets no Isha reminder — there's no next
      // day to end its window.
      for (final (key, kind) in _prayerOrder) {
        if (dayLog.containsKey(key)) continue;
        // Turning a prayer's notifications off turns off its reminder too.
        final mode = notifMode[key] ?? NotifMode.notification;
        if (mode == NotifMode.off) continue;
        final end = _windowEnd(days, i, key);
        if (end == null) continue;
        final naive = end.subtract(kPrayerEndingReminderLead);
        final scheduled = _toTz(naive, utcOffset, location);
        if (scheduled.isBefore(tz.TZDateTime.now(location))) continue;

        planned.add(
          _PlannedNotification(
            id: prayerEndReminderId(day.date, key),
            when: scheduled,
            title: t.notifPrayerEndingTitle(nameForPrayer(t, kind)),
            body: t.notifPrayerEndingBody(kPrayerEndingReminderLead.inMinutes),
            mode: _effectiveMode(mode, naive.hour, quietHoursEnabled),
            payload: '$dayKey|$key',
            actionLabel: t.notifMarkDoneAction,
          ),
        );
      }

      // A nudge to log the day's prayers — the prayer log otherwise depends
      // entirely on the user remembering to open the app and mark them.
      final reminderNaive = _combine(
        day.date,
        day.isha,
      ).add(const Duration(minutes: 45));
      final reminderScheduled = _toTz(reminderNaive, utcOffset, location);
      if (!reminderScheduled.isBefore(tz.TZDateTime.now(location))) {
        planned.add(
          _PlannedNotification(
            id: _notifId(day.date, _slotEveningReminder),
            when: reminderScheduled,
            title: t.notifEveningReminderTitle,
            body: t.notifEveningReminderBody,
            mode: _effectiveMode(
              NotifMode.notification,
              reminderNaive.hour,
              quietHoursEnabled,
            ),
            payload: null,
            actionLabel: null,
          ),
        );
      }
    }

    // Nearest first, so the part of the schedule anyone could actually
    // notice is in place before the rest.
    planned.sort((a, b) => a.when.compareTo(b.when));

    // No cancelAll(): ids are deterministic (see [_notifId]), so rebooking
    // overwrites in place, and only what the new schedule *doesn't* want —
    // a prayer just switched off, a day that has passed — needs cancelling.
    // cancelAll() plus ~90 re-bookings on every single toggle was what made
    // the notification settings feel like they hung.
    final wanted = {for (final p in planned) p.id};
    try {
      for (final pending in await _plugin.pendingNotificationRequests()) {
        if (generation != _generation) return;
        if (!wanted.contains(pending.id)) {
          await _plugin.cancel(id: pending.id);
        }
      }
    } catch (_) {
      // A platform that can't list pending notifications just keeps them;
      // they're overwritten by id anyway on the next pass.
    }

    // Today and tomorrow go in synchronously — that's the window a toggle
    // is really about, and it's ~20 bookings rather than ~90.
    final now = tz.TZDateTime.now(location);
    final horizon = now.add(_immediateHorizon);
    final soon = planned.where((p) => p.when.isBefore(horizon));
    for (final plan in soon) {
      if (generation != _generation) return;
      await _scheduleOne(plan);
    }

    // Everything further out is booked in small batches with the event loop
    // free in between, so the UI keeps its frames while it happens.
    final later = planned.where((p) => !p.when.isBefore(horizon)).toList();
    unawaited(_scheduleGradually(later, generation));
  }

  /// The stretch of schedule a change is immediately about — anything later
  /// can arrive over the next few seconds without anyone noticing.
  static const _immediateHorizon = Duration(hours: 36);
  static const _batchSize = 5;
  static const _batchGap = Duration(milliseconds: 120);

  Future<void> _scheduleGradually(
    List<_PlannedNotification> plans,
    int generation,
  ) async {
    for (var i = 0; i < plans.length; i += _batchSize) {
      await Future<void>.delayed(_batchGap);
      if (generation != _generation) return;
      for (final plan in plans.skip(i).take(_batchSize)) {
        if (generation != _generation) return;
        try {
          await _scheduleOne(plan);
        } catch (_) {
          // One booking failing (exact-alarm permission revoked mid-run,
          // say) shouldn't take the rest of the schedule with it.
        }
      }
    }
  }

  /// The id of the "window is closing" reminder for [prayerKey] on
  /// [prayerDate] — stable across reschedules (see [_notifId]) so a reminder
  /// scheduled by one [scheduleForDays] pass can be cancelled by a later,
  /// unrelated call.
  static int prayerEndReminderId(DateTime prayerDate, String prayerKey) =>
      _notifId(prayerDate, _prayerSlot(prayerKey) + 6);

  /// Drops the pending "window is closing" reminder for a prayer that's
  /// just been marked as prayed. A no-op when nothing is scheduled under
  /// that id (already fired, or never scheduled at all).
  Future<void> cancelPrayerEndReminder(DateTime date, String prayerKey) async {
    await _plugin.cancel(id: prayerEndReminderId(date, prayerKey));
  }

  /// City-local wall-clock end of [key]'s window on `days[index]` — where
  /// the next prayer starts. Null when that can't be known: Isha's window
  /// ends at the *following* day's Fajr, which the last entry in [days]
  /// doesn't have.
  DateTime? _windowEnd(List<PrayerDay> days, int index, String key) {
    final day = days[index];
    switch (key) {
      case 'fajr':
        return _combine(day.date, day.sunrise);
      case 'zuhr':
        return _combine(day.date, day.asr);
      case 'asr':
        return _combine(day.date, day.maghrib);
      case 'maghrib':
        return _combine(day.date, day.isha);
      case 'isha':
        if (index + 1 >= days.length) return null;
        final next = days[index + 1];
        return _combine(next.date, next.fajr);
      default:
        return null;
    }
  }

  // Quiet hours (22:00–06:00 city-local time) downgrade any sound to a
  // silent notification instead of skipping it outright.
  NotifMode _effectiveMode(NotifMode mode, int hour, bool quietHoursEnabled) =>
      quietHoursEnabled && _isQuietHour(hour) ? NotifMode.silent : mode;

  bool _isQuietHour(int hour) => hour >= 22 || hour < 6;

  /// [naive] is a city-local wall clock encoded the same way AppState.cityNow
  /// is (UTC-flagged DateTime whose fields are the city's local time) —
  /// subtracting the offset gives the real UTC instant tz can schedule.
  tz.TZDateTime _toTz(
    DateTime naive,
    Duration utcOffset,
    tz.Location location,
  ) => tz.TZDateTime.from(naive.subtract(utcOffset), location);

  Future<void> _scheduleOne(_PlannedNotification plan) async {
    final id = plan.id;
    final when = plan.when;
    final title = plan.title;
    final body = plan.body;
    final mode = plan.mode;
    final payload = plan.payload;
    final actionLabel = plan.actionLabel;
    // The "Прочитал"/"Done" action marks this prayer done on the prayer log
    // without opening the app — see _onResponse and
    // _notificationBackgroundHandler, which is why it's absent when there's
    // no payload to tell either of them which day/prayer this was.
    final actions = payload == null || actionLabel == null
        ? const <AndroidNotificationAction>[]
        : [
            AndroidNotificationAction(
              _markDoneActionId,
              actionLabel,
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ];

    final android = AndroidNotificationDetails(
      _notifChannelId,
      'Уведомления о намазе',
      channelDescription: 'Уведомление о наступлении времени намаза',
      importance: Importance.high,
      priority: Priority.high,
      playSound: mode == NotifMode.notification,
      actions: actions,
    );

    // NotifMode.off never reaches here — scheduleForDays skips those
    // prayers outright — so it falls in with the silent presentation.
    final darwin = mode == NotifMode.notification
        ? const DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.active,
          )
        : const DarwinNotificationDetails(presentSound: false);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Handles the "Прочитал"/"Done" action while the app process is alive
  // (foreground or backgrounded) — [onMarkDone] routes this through the
  // running AppState so its in-memory log updates immediately, not just the
  // disk copy.
  void _onResponse(NotificationResponse response) {
    if (response.actionId != _markDoneActionId) return;
    final parsed = _parseMarkDonePayload(response.payload);
    if (parsed == null) return;
    final (dateKey, prayerKey) = parsed;
    final date = DateTime.parse(dateKey);
    onMarkDone?.call(date, prayerKey);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  String _timeFor(PrayerDay day, String key) => switch (key) {
    'tahajjud' => day.tahajjud,
    'fajr' => day.fajr,
    'zuhr' => day.zuhr,
    'asr' => day.asr,
    'maghrib' => day.maghrib,
    'isha' => day.isha,
    _ => day.fajr,
  };

  DateTime _combine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}

class NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  /// Called from the first-run setup flow (see OnboardingScreen), not from
  /// [init] — asking on the very first frame, before anything has explained
  /// what the notifications are for, is how permission prompts get denied.
  Future<void> requestPermissions() async {}

  @override
  Future<void> requestNotificationsPermission() async {}

  @override
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required Duration utcOffset,
    required AppLocale locale,
    required bool quietHoursEnabled,
    bool includeTahajjud = false,
    Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
  }) async {}

  @override
  Future<void> cancelPrayerEndReminder(DateTime date, String prayerKey) async {}

  @override
  Future<void> cancelAll() async {}
}
