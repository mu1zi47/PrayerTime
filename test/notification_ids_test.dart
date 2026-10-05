import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/data/day_completion.dart';
import 'package:prayertime/services/notification_service.dart';

void main() {
  // Marking a prayer cancels its pending "window is closing" reminders by
  // id alone (see AppState.setPrayerStatus) — a collision would silence
  // some other day's or prayer's notification instead of these.
  test('prayer-end reminder ids are unique per day, prayer and reminder', () {
    final ids = <int>{};
    for (var offset = 0; offset < 800; offset++) {
      final date = DateTime(2026, 1, 1).add(Duration(days: offset));
      for (final key in requiredPrayerKeys) {
        for (final id in NotificationService.prayerEndReminderIds(date, key)) {
          expect(ids.add(id), isTrue, reason: 'duplicate id for $key on $date');
        }
      }
    }
  });

  // The Now Bar and the home-screen widget cancel these reminders natively
  // (android/.../EndReminders.kt), computing the ids the same way — these
  // are the numbers that file's comment quotes.
  test('reminder ids match the scheme the native side computes', () {
    expect(
      NotificationService.prayerEndReminderIds(DateTime(2026, 10, 5), 'zuhr'),
      [for (var id = 66408792; id <= 66408799; id++) id],
    );
    expect(
      NotificationService.prayerEndReminderIds(
        DateTime(2026, 10, 5),
        'fajr',
      ).first,
      66408784,
    );
    expect(
      NotificationService.prayerEndReminderIds(
        DateTime(2026, 10, 5),
        'isha',
      ).last,
      66408823,
    );
  });

  test('reminder ids stay inside the 32-bit range notifications allow', () {
    final ids = NotificationService.prayerEndReminderIds(
      DateTime(2099, 12, 31),
      'isha',
    );
    expect(ids.last, lessThan(1 << 31));
  });
}
