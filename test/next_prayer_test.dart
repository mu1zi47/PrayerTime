import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/data/next_prayer.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/widgets/prayer_icon.dart';

void main() {
  // AppState.cityNow encodes "wall clock time in the selected city" as a
  // UTC-flagged DateTime (see app_state.dart) — mirrored here so this test
  // is deterministic regardless of the machine's own timezone.
  final today = PrayerDay(
    date: DateTime.utc(2026, 8, 10),
    fajr: '03:19',
    sunrise: '05:52',
    zuhr: '12:47',
    asr: '16:37',
    maghrib: '19:53',
    isha: '21:42',
    tahajjud: '01:35',
  );
  final tomorrow = PrayerDay(
    date: DateTime.utc(2026, 8, 11),
    fajr: '03:21',
    sunrise: '05:53',
    zuhr: '12:46',
    asr: '16:35',
    maghrib: '19:51',
    isha: '21:40',
    tahajjud: '01:34',
  );

  test(
    'at 15:33, the next prayer is Asr (16:37), not something already past',
    () {
      final cityNow = DateTime.utc(2026, 8, 10, 15, 33);
      final next = computeNextPrayer([today, tomorrow], cityNow);

      expect(next?.kind, PrayerKind.asr);
      expect(next?.time, '16:37');
      expect(next?.remaining, const Duration(hours: 1, minutes: 4));
    },
  );

  test('after Isha, wraps to tomorrow\'s Fajr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 22, 0);
    final next = computeNextPrayer([today, tomorrow], cityNow);

    expect(next?.kind, PrayerKind.fajr);
    expect(next?.time, '03:21');
    expect(next?.date, tomorrow.date);
  });

  test(
    'after Isha with Tahajjud enabled, wraps to tomorrow\'s Tahajjud (not Fajr)',
    () {
      final cityNow = DateTime.utc(2026, 8, 10, 22, 0);
      final next = computeNextPrayer(
        [today, tomorrow],
        cityNow,
        includeTahajjud: true,
      );

      expect(next?.kind, PrayerKind.tahajjud);
      expect(next?.time, '01:34');
      expect(next?.date, tomorrow.date);
    },
  );

  test('right at midday, the next prayer is Zuhr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 9, 0);
    final next = computeNextPrayer([today, tomorrow], cityNow);

    expect(next?.kind, PrayerKind.zuhr);
    expect(next?.time, '12:47');
  });

  test('right after Fajr but before sunrise, the current prayer is Fajr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 4, 0);
    final current = computeCurrentPrayer([today, tomorrow], cityNow);
    expect(current?.kind, PrayerKind.fajr);
    expect(current?.date, today.date);
    expect(current?.isFromPreviousDay, false);
  });

  test('between sunrise and Zuhr, no prayer is current (not still Fajr)', () {
    final cityNow = DateTime.utc(2026, 8, 10, 9, 0);
    expect(
      computeCurrentPrayer([today, tomorrow], cityNow)?.kind,
      PrayerKind.sunrise,
    );
  });

  test(
    'just after midnight, before Fajr, current prayer is still yesterday\'s Isha',
    () {
      // cityNow is now on `tomorrow`'s date, before its Fajr — with
      // `tomorrow` at todayIndex 1, `today` (index 0) is "yesterday".
      final cityNow = DateTime.utc(2026, 8, 11, 0, 30);
      final current = computeCurrentPrayer(
        [today, tomorrow],
        cityNow,
        todayIndex: 1,
      );
      expect(current?.kind, PrayerKind.isha);
      expect(current?.date, today.date);
      expect(current?.time, today.isha);
      expect(current?.isFromPreviousDay, true);
    },
  );

  test(
    'just after midnight with no previous day on hand, current prayer is null',
    () {
      final cityNow = DateTime.utc(2026, 8, 11, 0, 30);
      expect(computeCurrentPrayer([tomorrow], cityNow), null);
    },
  );
}
