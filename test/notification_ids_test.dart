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

  test('reminder ids stay inside the 32-bit range notifications allow', () {
    final ids = NotificationService.prayerEndReminderIds(
      DateTime(2099, 12, 31),
      'isha',
    );
    expect(ids.last, lessThan(1 << 31));
  });
}
