import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/models/app_locale.dart';
import 'package:prayertime/models/end_reminders.dart';
import 'package:prayertime/models/notif_mode.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/models/prayer_log_status.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';

class _InstantFakeApi extends PrayerTimesApi {
  @override
  Future<PrayerFetchResult> fetchDaysWindow({
    required City city,
    required int methodCode,
    required int school,
    required DateTime centerDay,
    required int pastDays,
    required int futureDays,
    String? tune,
  }) async => PrayerFetchResult(days: _days, timeZone: city.timeZone);
}

PrayerDay _day(int day) => PrayerDay(
  date: DateTime(2030, 6, day),
  fajr: '05:00',
  sunrise: '06:30',
  zuhr: '12:30',
  asr: '15:30',
  maghrib: '18:30',
  isha: '20:00',
  tahajjud: '02:30',
);

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

final _days = [_day(1), _day(2), _day(3)];
final _now = tz.TZDateTime(tz.UTC, 2030, 5, 31);

const _allOn = {
  'fajr': NotifMode.notification,
  'zuhr': NotifMode.notification,
  'asr': NotifMode.notification,
  'maghrib': NotifMode.notification,
  'isha': NotifMode.notification,
};

List<PlannedNotification> _plan({
  Map<String, List<int>> endReminders = const {},
  Map<String, Map<String, Set<int>>> endRemindersOff = const {},
  Map<String, NotifMode> notifMode = _allOn,
  Map<String, Map<String, PrayerLogStatus>> prayerLog = const {},
}) => NotificationService().plan(
  days: _days,
  notifMode: notifMode,
  utcOffset: Duration.zero,
  locale: AppLocale.ru,
  now: _now,
  prayerLog: prayerLog,
  endReminders: endReminders,
  endRemindersOff: endRemindersOff,
);

/// When each "window is closing" reminder for [key] goes off on June [day].
List<DateTime> _endRemindersAt(
  List<PlannedNotification> plan,
  String key,
  int day,
) => [
  for (final p in plan)
    if (p.payload == '2030-06-${day.toString().padLeft(2, '0')}|$key' &&
        p.body.startsWith('Осталось'))
      DateTime.utc(
        p.when.year,
        p.when.month,
        p.when.day,
        p.when.hour,
        p.when.minute,
      ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService.plan', () {
    test('books every reminder a prayer has, each its lead before the end', () {
      final plan = _plan(
        endReminders: {
          'fajr': [60, 30],
          'zuhr': [15],
        },
      );

      expect(_endRemindersAt(plan, 'fajr', 1), [
        DateTime.utc(2030, 6, 1, 5, 30),
        DateTime.utc(2030, 6, 1, 6, 0),
      ]);
      expect(_endRemindersAt(plan, 'zuhr', 1), [
        DateTime.utc(2030, 6, 1, 15, 15),
      ]);
      expect(_endRemindersAt(plan, 'asr', 1), isEmpty);
      expect({for (final p in plan) p.id}.length, plan.length);
    });

    test('says how long is left in the reminder itself', () {
      final plan = _plan(
        endReminders: {
          'zuhr': [90],
        },
      );
      final reminder = plan.firstWhere(
        (p) => p.payload == '2030-06-01|zuhr' && p.body.startsWith('Осталось'),
      );
      expect(reminder.body, startsWith('Осталось 1 ч 30 мин'));
    });

    test('skips a lead longer than the whole window', () {
      // Maghrib runs 18:30–20:00 here: two hours before its end is before
      // it has even started.
      final plan = _plan(
        endReminders: {
          'maghrib': [120, 90, 20],
        },
      );
      expect(_endRemindersAt(plan, 'maghrib', 1), [
        // The whole window is still allowed: it lands on the start itself.
        DateTime.utc(2030, 6, 1, 18, 30),
        DateTime.utc(2030, 6, 1, 19, 40),
      ]);
    });

    test('a reminder switched off for a day skips that day alone', () {
      final plan = _plan(
        endReminders: {
          'fajr': [60, 30],
        },
        endRemindersOff: {
          '2030-06-01': {
            'fajr': {30},
          },
        },
      );
      expect(_endRemindersAt(plan, 'fajr', 1), [
        DateTime.utc(2030, 6, 1, 5, 30),
      ]);
      expect(_endRemindersAt(plan, 'fajr', 2), hasLength(2));
    });

    test('a marked prayer, or one switched off, gets no reminders', () {
      final plan = _plan(
        endReminders: {
          'fajr': [30],
          'asr': [30],
        },
        notifMode: {..._allOn, 'asr': NotifMode.off},
        prayerLog: {
          '2030-06-01': {'fajr': PrayerLogStatus.onTime},
        },
      );
      expect(_endRemindersAt(plan, 'fajr', 1), isEmpty);
      expect(_endRemindersAt(plan, 'fajr', 2), isNotEmpty);
      expect(_endRemindersAt(plan, 'asr', 1), isEmpty);
    });

    test("the last day's Isha has no end to count back from", () {
      final plan = _plan(
        endReminders: {
          'isha': [30],
        },
      );
      expect(_endRemindersAt(plan, 'isha', 2), [
        DateTime.utc(2030, 6, 3, 4, 30),
      ]);
      expect(_endRemindersAt(plan, 'isha', 3), isEmpty);
    });
  });

  test('a reminder list keeps no repeats, nothing out of range, at most '
      '$kMaxEndReminders, longest lead first', () {
    expect(normalizeEndReminders([10, 30, 10, 0, 400, 60]), [60, 30, 10]);
    expect(normalizeEndReminders([5, 10, 15, 20, 25, 30, 35]), [
      35,
      30,
      25,
      20,
      15,
    ]);
  });

  group('maxEndReminderLead', () {
    test('is the whole window, down to a whole five minutes', () {
      // Fajr 05:00–06:30 and Zuhr 12:30–15:30 here.
      expect(maxEndReminderLead(_days, 'fajr'), 90);
      expect(maxEndReminderLead(_days, 'zuhr'), 180);
      final odd = PrayerDay(
        date: DateTime(2030, 6, 1),
        fajr: '05:00',
        sunrise: '06:14',
        zuhr: '12:30',
        asr: '15:30',
        maghrib: '18:30',
        isha: '20:00',
        tahajjud: '02:30',
      );
      expect(maxEndReminderLead([odd], 'fajr'), 70);
    });

    test('goes by the shortest window on hand', () {
      final shorter = PrayerDay(
        date: DateTime(2030, 6, 4),
        fajr: '05:00',
        sunrise: '06:30',
        zuhr: '12:30',
        asr: '15:30',
        maghrib: '18:30',
        isha: '19:50',
        tahajjud: '02:30',
      );
      // 90 minutes of Maghrib on the others, 80 on this one.
      expect(maxEndReminderLead([..._days, shorter], 'maghrib'), 80);
    });

    test("stays within the picker's own range", () {
      // Isha runs nine hours here, to the next day's Fajr.
      expect(maxEndReminderLead(_days, 'isha'), kMaxEndReminderMinutes);
      expect(maxEndReminderLead(const [], 'fajr'), kMaxEndReminderMinutes);
    });
  });

  test('leads read as hours and minutes', () {
    final t = lookupAppLocalizations(const Locale('ru'));
    expect(formatLeadTime(t, 30), '30 мин');
    expect(formatLeadTime(t, 60), '1 ч');
    expect(formatLeadTime(t, 90), '1 ч 30 мин');
  });

  group('AppState', () {
    AppState newState() => AppState(
      api: _InstantFakeApi(),
      notifications: NoopNotificationService(),
      connectivity: const _AlwaysOnline(),
      installTimes: () async => null,
    );

    setUp(() => SharedPreferences.setMockInitialValues({'locale': 'ru'}));

    test('starts every prayer on the default reminder', () {
      final appState = newState();
      expect(appState.endRemindersFor('fajr'), kDefaultEndReminders);
      expect(appState.endRemindersFor('tahajjud'), isEmpty);
    });

    test('adds, changes and removes reminders, refusing repeats and '
        'going over the limit', () {
      final appState = newState();
      expect(appState.addEndReminder('asr', 10), isTrue);
      expect(appState.addEndReminder('asr', 10), isFalse);
      expect(appState.endRemindersFor('asr'), [30, 10]);

      expect(appState.changeEndReminder('asr', 10, 30), isFalse);
      expect(appState.changeEndReminder('asr', 10, 45), isTrue);
      expect(appState.endRemindersFor('asr'), [45, 30]);

      appState.removeEndReminder('asr', 30);
      expect(appState.endRemindersFor('asr'), [45]);

      for (final m in [5, 10, 15, 20]) {
        appState.addEndReminder('asr', m);
      }
      expect(appState.endRemindersFor('asr'), hasLength(kMaxEndReminders));
      expect(appState.addEndReminder('asr', 25), isFalse);
    });

    test('switches one off for today, back on, and keeps it through '
        'changing its lead', () {
      final appState = newState();
      appState.toggleEndReminderOffToday('zuhr', 30);
      expect(appState.isEndReminderOffToday('zuhr', 30), isTrue);
      expect(appState.isEndReminderOffToday('asr', 30), isFalse);

      appState.changeEndReminder('zuhr', 30, 20);
      expect(appState.isEndReminderOffToday('zuhr', 20), isTrue);

      appState.toggleEndReminderOffToday('zuhr', 20);
      expect(appState.isEndReminderOffToday('zuhr', 20), isFalse);
    });

    test('keeps them across a restart', () async {
      final before = newState();
      before.addEndReminder('isha', 60);
      before.removeEndReminder('fajr', 30);
      before.toggleEndReminderOffToday('isha', 60);
      await pumpEventQueue();

      final after = newState();
      await after.init();
      expect(after.endRemindersFor('isha'), [60, 30]);
      expect(after.endRemindersFor('fajr'), isEmpty);
      expect(after.endRemindersFor('zuhr'), kDefaultEndReminders);
      expect(after.isEndReminderOffToday('isha', 60), isTrue);
      expect(after.isEndReminderOffToday('isha', 30), isFalse);
    });
  });
}
