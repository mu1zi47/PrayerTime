import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/main.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';

class _InstantFakeApi extends PrayerTimesApi {
  @override
  Future<List<PrayerDay>> fetchUpcomingDays({
    required City city,
    required int methodCode,
    required int school,
    required DateTime from,
    String? tune,
    int count = 10,
  }) async {
    return [
      PrayerDay(date: from, fajr: '05:00', sunrise: '06:30', zuhr: '12:30', asr: '15:30', maghrib: '18:30', isha: '20:00'),
    ];
  }
}

void main() {
  setUp(() {
    // AppState.init() reads persisted settings on startup — keep tests
    // isolated from real device storage and from each other.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders the home screen and switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      PrayerTimeApp(
        appState: AppState(api: _InstantFakeApi(), notifications: NoopNotificationService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
    expect(find.text('Настройки'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsWidgets);
  });
}
