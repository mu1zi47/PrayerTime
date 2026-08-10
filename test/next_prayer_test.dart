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
  );
  final tomorrow = PrayerDay(
    date: DateTime.utc(2026, 8, 11),
    fajr: '03:21',
    sunrise: '05:53',
    zuhr: '12:46',
    asr: '16:35',
    maghrib: '19:51',
    isha: '21:40',
  );

  test('at 15:33, the next prayer is Asr (16:37), not something already past', () {
    final cityNow = DateTime.utc(2026, 8, 10, 15, 33);
    final next = computeNextPrayer([today, tomorrow], cityNow);

    expect(next?.kind, PrayerKind.asr);
    expect(next?.time, '16:37');
    expect(next?.remaining, const Duration(hours: 1, minutes: 4));
  });

  test('after Isha, wraps to tomorrow\'s Fajr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 22, 0);
    final next = computeNextPrayer([today, tomorrow], cityNow);

    expect(next?.kind, PrayerKind.fajr);
    expect(next?.time, '03:21');
  });

  test('right at midday, the next prayer is Zuhr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 9, 0);
    final next = computeNextPrayer([today, tomorrow], cityNow);

    expect(next?.kind, PrayerKind.zuhr);
    expect(next?.time, '12:47');
  });

  test('right after Fajr but before sunrise, the current prayer is Fajr', () {
    final cityNow = DateTime.utc(2026, 8, 10, 4, 0);
    expect(computeCurrentPrayer([today, tomorrow], cityNow), PrayerKind.fajr);
  });

  test('between sunrise and Zuhr, no prayer is current (not still Fajr)', () {
    final cityNow = DateTime.utc(2026, 8, 10, 9, 0);
    expect(computeCurrentPrayer([today, tomorrow], cityNow), PrayerKind.sunrise);
  });
}
