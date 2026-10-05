import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

import '../data/prayer_window.dart';
import '../data/timezone_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/end_reminders.dart';
import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../widgets/prayer_icon.dart';
import 'now_bar_bridge.dart';
import 'prayer_log_store.dart';

// Every prayer gets its own notification channel, and Android fixes a
// channel's sound once it exists — so the sound is part of the id, and
// picking another one moves the prayer to a fresh channel (see
// NotificationService.channelIdFor and _syncChannels).
const _channelPrefix = 'prayer_sound_';

// The single channel everything went out on before sounds could be picked;
// deleted once the per-prayer channels are in place.
const _legacyChannelId = 'prayer_notification';

/// The channel key of notifications that aren't about one prayer — the
/// evening "mark your prayers" nudge. Its sound is the shared one.
const kGeneralSoundKey = 'general';

// The "Прочитал"/"Done" action button on a prayer-time notification — see
// NotificationService._onResponse and _notificationBackgroundHandler.
const _markDoneActionId = 'mark_done';

const _prayerOrder = [
  ('fajr', PrayerKind.fajr),
  ('zuhr', PrayerKind.zuhr),
  ('asr', PrayerKind.asr),
  ('maghrib', PrayerKind.maghrib),
  ('isha', PrayerKind.isha),
];

// Every prayer-day owns a fixed block of ids, one per slot below, so a
// single scheduled notification can be addressed (and cancelled) on its own
// later — see NotificationService.cancelPrayerEndReminders, which is how
// marking a prayer prayed silences its pending reminders without rebuilding
// the whole schedule.
//
// Slots 0–5 are the prayers themselves (see [_prayerSlot]), 15 the evening
// reminder, and from 16 on each of the five prayers has
// [_endReminderSlotsPerPrayer] slots for its "window is closing" reminders.
const _slotsPerDay = 64;
const _slotEveningReminder = 15;
const _slotFirstEndReminder = 16;
const _endReminderSlotsPerPrayer = 8;

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

/// The slot of [prayerKey]'s [n]th "window is closing" reminder — counted
/// from Fajr, since Tahajjud gets none.
int _endReminderSlot(String prayerKey, int n) =>
    _slotFirstEndReminder +
    (_prayerSlot(prayerKey) - 1) * _endReminderSlotsPerPrayer +
    n;

/// Runs in a fresh, isolated Dart isolate with no access to any running
/// AppState — the app process was fully terminated when the action fired.
/// Writes straight to shared_preferences via [PrayerLogStore], the same
/// on-disk format AppState itself reads/writes.
@pragma('vm:entry-point')
Future<void> _notificationBackgroundHandler(
  NotificationResponse response,
) async {
  if (response.actionId != _markDoneActionId) return;
  final parsed = _parseMarkDonePayload(response.payload);
  if (parsed == null) return;
  final (dateKey, prayerKey) = parsed;
  // This isolate runs on an engine the plugin started just for the action,
  // where plugins with a Dart side (shared_preferences, this plugin itself)
  // aren't registered until asked. Without it, the cancels below found no
  // Android implementation to go through and quietly did nothing — so the
  // "window is closing" reminders still went off for a prayer marked right
  // here.
  DartPluginRegistrant.ensureInitialized();
  try {
    await PrayerLogStore.markOnTime(dateKey, prayerKey);
  } catch (_) {
    // Not saved — the reminders below are still worth silencing.
  }
  // Same reason AppState.setPrayerStatus does this — a prayer marked from
  // the notification itself shouldn't still get nagged about later.
  final plugin = FlutterLocalNotificationsPlugin();
  final ids = NotificationService.prayerEndReminderIds(
    DateTime.parse(dateKey),
    prayerKey,
  );
  for (final id in ids) {
    try {
      await plugin.cancel(id: id);
    } catch (_) {
      // Nothing booked under this id, or no channel — move on.
    }
  }
}

(String, String)? _parseMarkDonePayload(String? payload) {
  if (payload == null) return null;
  final parts = payload.split('|');
  if (parts.length != 2) return null;
  return (parts[0], parts[1]);
}

/// One notification the schedule says should exist, before anything has
/// been handed to the platform — see [NotificationService.scheduleForDays],
/// which builds the whole list first (see [NotificationService.plan]) and
/// only then books it, nearest first and in small batches.
class PlannedNotification {
  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;
  final NotifMode mode;
  final String? payload;
  final String? actionLabel;

  /// Which channel it goes out on — a prayer's key, or [kGeneralSoundKey] —
  /// with [sound] (the phone's default when null) and [channelName], what
  /// the phone's settings list that channel as.
  final String channel;
  final String channelName;
  final String? sound;

  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.mode,
    required this.payload,
    required this.actionLabel,
    required this.channel,
    required this.channelName,
    required this.sound,
  });

  String get channelId => NotificationService.channelIdFor(channel, sound);
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
    // No channels here: which ones there should be depends on the sounds
    // picked, and scheduleForDays sets them up (see _syncChannels).
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
  /// notification, which needs nothing else, and for asking again from the
  /// notification settings after the first prompt was refused.
  Future<void> requestNotificationsPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Whether anything scheduled here would actually be shown: notifications
  /// allowed for the app and, on Android, not every prayer channel blocked
  /// on its own in system settings — that reads as allowed at the app
  /// level, but nothing posted ever appears. One prayer's channel blocked
  /// is a choice about that prayer, not notifications being off. Null when
  /// the platform won't say.
  Future<bool?> areNotificationsAllowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled != true) return enabled;
      final ours = [
        for (final c in await android.getNotificationChannels() ?? const [])
          if (c.id.startsWith(_channelPrefix)) c,
      ];
      return ours.isEmpty || ours.any((c) => c.importance != Importance.none);
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) return (await ios.checkPermissions())?.isEnabled;
    return null;
  }

  /// The app's page in the phone's notification settings — the only way
  /// back once the system prompt has been refused for good (iOS after the
  /// first time, Android after the second), or when just the prayer channel
  /// was switched off there.
  Future<void> openSystemSettings() async {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await const NowBarBridge().openNotificationSettings();
      case TargetPlatform.iOS:
        try {
          await launchUrl(Uri.parse('app-settings:'));
        } catch (_) {
          // Nothing else to offer; the notice still says what to change.
        }
      default:
        break;
    }
  }

  /// [prayerLog] is AppState's own log, in the same shape it keeps it —
  /// a prayer already marked there gets no "window is closing" reminders,
  /// since there's nothing left to remind about (see
  /// [cancelPrayerEndReminders] for the same thing happening after the
  /// fact, when a prayer is marked while its reminders are already
  /// scheduled). [endReminders] holds each prayer's reminder leads in
  /// minutes, as AppState keeps them, and [endRemindersOff] the ones
  /// switched off for a single day: by that day's date key, then prayer.
  /// [sounds] is each prayer's sound URI, and [kGeneralSoundKey]'s — the
  /// phone's default where it's null or missing.
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required Duration utcOffset,
    required AppLocale locale,
    bool includeTahajjud = false,
    Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
    Map<String, List<int>> endReminders = const {},
    Map<String, Map<String, Set<int>>> endRemindersOff = const {},
    Map<String, String?> sounds = const {},
  }) async {
    final generation = ++_generation;
    final location = tz.UTC;
    final planned = plan(
      days: days,
      notifMode: notifMode,
      utcOffset: utcOffset,
      locale: locale,
      includeTahajjud: includeTahajjud,
      prayerLog: prayerLog,
      endReminders: endReminders,
      endRemindersOff: endRemindersOff,
      sounds: sounds,
      now: tz.TZDateTime.now(location),
    );

    try {
      await _syncChannels(planned);
    } catch (_) {
      // Booking still goes ahead: the plugin creates a missing channel
      // itself, just without the sound picked for it.
    }
    if (generation != _generation) return;

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
    List<PlannedNotification> plans,
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

  /// Everything [scheduleForDays] books, nearest first — what should be
  /// pending once it's done. Split out so the schedule can be checked
  /// without a platform to book it on.
  @visibleForTesting
  List<PlannedNotification> plan({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required Duration utcOffset,
    required AppLocale locale,
    required tz.TZDateTime now,
    bool includeTahajjud = false,
    Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
    Map<String, List<int>> endReminders = const {},
    Map<String, Map<String, Set<int>>> endRemindersOff = const {},
    Map<String, String?> sounds = const {},
  }) {
    final t = lookupAppLocalizations(locale.localeValue);
    final location = tz.UTC;
    final planned = <PlannedNotification>[];

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
        final naive = prayerWindowStart(day, key);
        final scheduled = _toTz(naive, utcOffset, location);
        if (scheduled.isBefore(now)) continue;

        // Tahajjud isn't one of the five prayers tracked on the prayer log,
        // so it gets no mark-done action — there's nowhere for that mark to
        // show up.
        final payload = key == 'tahajjud' ? null : '$dayKey|$key';
        planned.add(
          PlannedNotification(
            id: _notifId(day.date, _prayerSlot(key)),
            when: scheduled,
            title: t.notifPlainTitle(nameForPrayer(t, kind)),
            body: t.notifBody,
            mode: mode,
            payload: payload,
            actionLabel: t.notifMarkDoneAction,
            channel: key,
            channelName: nameForPrayer(t, kind),
            sound: sounds[key],
          ),
        );
      }

      // The last calls before each prayer's window closes, for a prayer that
      // still isn't marked as prayed — as many as were set for it, each
      // [endReminders] minutes ahead of the end. The window ends where the
      // next one starts (see prayerWindowEnd), so the very last day on hand
      // gets no Isha reminders — there's no next day to end its window.
      for (final (key, kind) in _prayerOrder) {
        if (dayLog.containsKey(key)) continue;
        // Turning a prayer's notifications off turns off its reminders too.
        final mode = notifMode[key] ?? NotifMode.notification;
        if (mode == NotifMode.off) continue;
        final end = prayerWindowEnd(days, i, key);
        if (end == null) continue;
        final start = prayerWindowStart(day, key);
        final leads = endReminders[key] ?? const <int>[];
        final off = endRemindersOff[dayKey]?[key] ?? const <int>{};

        for (var n = 0; n < leads.length; n++) {
          if (n >= _endReminderSlotsPerPrayer) break;
          final lead = leads[n];
          if (off.contains(lead)) continue;
          final naive = end.subtract(Duration(minutes: lead));
          // A lead longer than the whole window (two hours before the end
          // of a 70-minute Maghrib) would land before the prayer has even
          // begun — there's nothing to remind about yet. The picker doesn't
          // offer one (see maxEndReminderLead); this is for leads set under
          // another city's longer windows.
          if (naive.isBefore(start)) continue;
          final scheduled = _toTz(naive, utcOffset, location);
          if (scheduled.isBefore(now)) continue;

          planned.add(
            PlannedNotification(
              id: _notifId(day.date, _endReminderSlot(key, n)),
              when: scheduled,
              title: t.notifPrayerEndingTitle(nameForPrayer(t, kind)),
              body: t.notifPrayerEndingBody(formatLeadTime(t, lead)),
              mode: mode,
              payload: '$dayKey|$key',
              actionLabel: t.notifMarkDoneAction,
              // A prayer's reminders sound like the prayer itself.
              channel: key,
              channelName: nameForPrayer(t, kind),
              sound: sounds[key],
            ),
          );
        }
      }

      // A nudge to log the day's prayers — the prayer log otherwise depends
      // entirely on the user remembering to open the app and mark them.
      final reminderNaive = prayerWindowStart(
        day,
        'isha',
      ).add(const Duration(minutes: 45));
      final reminderScheduled = _toTz(reminderNaive, utcOffset, location);
      if (!reminderScheduled.isBefore(now)) {
        planned.add(
          PlannedNotification(
            id: _notifId(day.date, _slotEveningReminder),
            when: reminderScheduled,
            title: t.notifEveningReminderTitle,
            body: t.notifEveningReminderBody,
            mode: NotifMode.notification,
            payload: null,
            actionLabel: null,
            channel: kGeneralSoundKey,
            channelName: t.soundEveningReminder,
            sound: sounds[kGeneralSoundKey],
          ),
        );
      }
    }

    // Nearest first, so the part of the schedule anyone could actually
    // notice is in place before the rest.
    planned.sort((a, b) => a.when.compareTo(b.when));
    return planned;
  }

  /// The channel a notification of [key] — a prayer's, or
  /// [kGeneralSoundKey] — goes out on with [soundUri] (the phone's default
  /// when null). Stable for the same pair, different for any other.
  static String channelIdFor(String key, String? soundUri) =>
      '$_channelPrefix${key}_${soundUri == null ? 'default' : _soundTag(soundUri)}';

  /// A short, stable stand-in for a sound URI inside a channel id (FNV-1a).
  static String _soundTag(String uri) {
    var hash = 0x811c9dc5;
    for (final unit in uri.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Makes sure every channel [planned] goes out on exists with its sound,
  /// and drops the ones nothing does any more — a sound picked over, and
  /// the single channel from before sounds could be picked. A channel's
  /// name is set again each time, so it follows the app's language.
  Future<void> _syncChannels(List<PlannedNotification> planned) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final wanted = <String, PlannedNotification>{
      for (final p in planned) p.channelId: p,
    };
    for (final p in wanted.values) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          p.channelId,
          p.channelName,
          importance: Importance.high,
          sound: p.sound == null ? null : UriAndroidNotificationSound(p.sound!),
        ),
      );
    }
    for (final channel in await android.getNotificationChannels() ?? const []) {
      final stale =
          channel.id == _legacyChannelId ||
          (channel.id.startsWith(_channelPrefix) &&
              !wanted.containsKey(channel.id));
      if (stale) await android.deleteNotificationChannel(channelId: channel.id);
    }
  }

  /// The ids every "window is closing" reminder for [prayerKey] on
  /// [prayerDate] can have — stable across reschedules (see [_notifId]), so
  /// reminders scheduled by one [scheduleForDays] pass can be cancelled by a
  /// later, unrelated call.
  static List<int> prayerEndReminderIds(
    DateTime prayerDate,
    String prayerKey,
  ) => [
    for (var n = 0; n < _endReminderSlotsPerPrayer; n++)
      _notifId(prayerDate, _endReminderSlot(prayerKey, n)),
  ];

  /// Drops the pending "window is closing" reminders for a prayer that's
  /// just been marked as prayed. Every slot is cleared, not only the ones
  /// in use, which costs nothing for ids with nothing scheduled under them.
  Future<void> cancelPrayerEndReminders(DateTime date, String prayerKey) async {
    for (final id in prayerEndReminderIds(date, prayerKey)) {
      await _plugin.cancel(id: id);
    }
  }

  /// [naive] is a city-local wall clock encoded the same way AppState.cityNow
  /// is (UTC-flagged DateTime whose fields are the city's local time) —
  /// subtracting the offset gives the real UTC instant tz can schedule.
  tz.TZDateTime _toTz(
    DateTime naive,
    Duration utcOffset,
    tz.Location location,
  ) => tz.TZDateTime.from(naive.subtract(utcOffset), location);

  Future<void> _scheduleOne(PlannedNotification plan) async {
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

    // The channel carries the sound (see _syncChannels); a silent one is
    // silenced here instead. Android 8+ ignores a single notification's own
    // sound settings, so turning `playSound` off — as this used to — left
    // "silent" prayers playing the channel's sound all along.
    final android = AndroidNotificationDetails(
      plan.channelId,
      plan.channelName,
      importance: Importance.high,
      priority: Priority.high,
      sound: plan.sound == null
          ? null
          : UriAndroidNotificationSound(plan.sound!),
      silent: mode != NotifMode.notification,
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
  Future<bool?> areNotificationsAllowed() async => true;

  @override
  Future<void> openSystemSettings() async {}

  @override
  Future<void> scheduleForDays({
    required List<PrayerDay> days,
    required Map<String, NotifMode> notifMode,
    required Duration utcOffset,
    required AppLocale locale,
    bool includeTahajjud = false,
    Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
    Map<String, List<int>> endReminders = const {},
    Map<String, Map<String, Set<int>>> endRemindersOff = const {},
    Map<String, String?> sounds = const {},
  }) async {}

  @override
  Future<void> cancelPrayerEndReminders(
    DateTime date,
    String prayerKey,
  ) async {}

  @override
  Future<void> cancelAll() async {}
}
