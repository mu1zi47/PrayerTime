import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/data/day_completion.dart';
import 'package:prayertime/models/prayer_log_status.dart';

void main() {
  Map<String, PrayerLogStatus> fullDay({bool allOnTime = true}) => {
    for (final k in requiredPrayerKeys)
      k: allOnTime ? PrayerLogStatus.onTime : PrayerLogStatus.qada,
  };

  group('classifyDay', () {
    test('all five on time is onTime', () {
      expect(classifyDay(fullDay(), isLocked: true), DayCompletion.onTime);
    });

    test('all five marked but one late is qada', () {
      final log = fullDay()..['isha'] = PrayerLogStatus.qada;
      expect(classifyDay(log, isLocked: true), DayCompletion.qada);
    });

    test('incomplete and locked is missed', () {
      expect(classifyDay(const {}, isLocked: true), DayCompletion.missed);
    });

    test('incomplete but not locked yet is upcoming, not missed', () {
      expect(classifyDay(const {}, isLocked: false), DayCompletion.upcoming);
    });
  });
}
