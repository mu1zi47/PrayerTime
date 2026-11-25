import 'package:flutter_test/flutter_test.dart';
import 'package:fiveglow/data/day_completion.dart';
import 'package:fiveglow/models/prayer_log_status.dart';

void main() {
  Map<String, PrayerLogStatus> fullDay() => {
    for (final k in requiredPrayerKeys) k: PrayerLogStatus.onTime,
  };

  group('classifyDay', () {
    test('all five on time is onTime', () {
      expect(classifyDay(fullDay(), isLocked: true), DayCompletion.onTime);
    });

    test('legacy late mark is read and completes the day', () {
      final log = fullDay()..['isha'] = PrayerLogStatus.fromName('qada')!;
      expect(classifyDay(log, isLocked: true), DayCompletion.onTime);
    });

    test('incomplete and locked is missed', () {
      expect(classifyDay(const {}, isLocked: true), DayCompletion.missed);
    });

    test('incomplete but not locked yet is upcoming, not missed', () {
      expect(classifyDay(const {}, isLocked: false), DayCompletion.upcoming);
    });
  });
}
