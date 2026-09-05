import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/data/day_completion.dart';
import 'package:prayertime/services/notification_service.dart';

void main() {
  // Marking a prayer cancels its pending "window is closing" reminder by id
  // alone (see AppState.setPrayerStatus) — a collision would silence some
  // other day's or prayer's notification instead of this one.
  test('prayer-end reminder ids are unique per day and prayer', () {
    final ids = <int>{};
    for (var offset = 0; offset < 800; offset++) {
      final date = DateTime(2026, 1, 1).add(Duration(days: offset));
      for (final key in requiredPrayerKeys) {
        expect(
          ids.add(NotificationService.prayerEndReminderId(date, key)),
          isTrue,
          reason: 'duplicate id for $key on $date',
        );
      }
    }
  });

  test('reminder ids stay inside the 32-bit range notifications allow', () {
    final id = NotificationService.prayerEndReminderId(
      DateTime(2099, 12, 31),
      'isha',
    );
    expect(id, lessThan(1 << 31));
  });
}
