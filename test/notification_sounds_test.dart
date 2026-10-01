import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayertime/models/app_locale.dart';
import 'package:prayertime/models/notif_mode.dart';
import 'package:prayertime/models/notif_sound.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';

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

final _days = [_day(1), _day(2)];

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

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

const _chime = NotifSound(
  uri: 'content://media/internal/audio/1',
  title: 'Chime',
);
const _bell = NotifSound(
  uri: 'content://media/internal/audio/2',
  title: 'Bell',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    List<PlannedNotification> plan(Map<String, String?> sounds) =>
        NotificationService().plan(
          days: _days,
          notifMode: const {
            'fajr': NotifMode.notification,
            'zuhr': NotifMode.silent,
            'asr': NotifMode.notification,
            'maghrib': NotifMode.notification,
            'isha': NotifMode.notification,
          },
          utcOffset: Duration.zero,
          locale: AppLocale.ru,
          now: tz.TZDateTime(tz.UTC, 2030, 5, 31),
          endReminders: const {
            'fajr': [30],
          },
          sounds: sounds,
        );

    test("each prayer, its reminders included, goes out on its own sound's "
        'channel; the evening reminder on the shared one', () {
      final planned = plan({
        'fajr': _chime.uri,
        'zuhr': _bell.uri,
        kGeneralSoundKey: null,
      });
      final fajr = planned.where((p) => p.channel == 'fajr').toList();
      expect(fajr.map((p) => p.sound).toSet(), {_chime.uri});
      // The prayer itself and its "window is closing" reminder.
      expect(fajr.length, 4);
      expect(
        planned.firstWhere((p) => p.channel == 'zuhr').channelId,
        NotificationService.channelIdFor('zuhr', _bell.uri),
      );
      final evening = planned.where((p) => p.channel == kGeneralSoundKey);
      expect(evening, hasLength(2));
      expect(evening.first.sound, isNull);
      // Asr was given no sound: the phone's default.
      expect(planned.firstWhere((p) => p.channel == 'asr').sound, isNull);
    });

    test('a different sound means a different channel, the same one the '
        'same', () {
      final a = NotificationService.channelIdFor('fajr', _chime.uri);
      expect(NotificationService.channelIdFor('fajr', _chime.uri), a);
      expect(NotificationService.channelIdFor('fajr', _bell.uri), isNot(a));
      expect(NotificationService.channelIdFor('fajr', null), isNot(a));
      expect(NotificationService.channelIdFor('zuhr', _chime.uri), isNot(a));
    });
  });

  group('AppState', () {
    AppState newState() => AppState(
      api: _InstantFakeApi(),
      notifications: NoopNotificationService(),
      connectivity: const _AlwaysOnline(),
      installTimes: () async => null,
    );

    setUp(() => SharedPreferences.setMockInitialValues({'locale': 'ru'}));

    test('one sound for every notification, kept across a restart', () async {
      final before = newState();
      expect(before.sharedSound, const NotifSound.phoneDefault());
      before.setSharedSound(_chime);
      await pumpEventQueue();

      final after = newState();
      await after.init();
      expect(after.sharedSound, _chime);
      expect(after.sharedSound.title, 'Chime');
    });
  });
}
