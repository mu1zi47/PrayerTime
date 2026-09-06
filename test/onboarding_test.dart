import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/main.dart';
import 'package:prayertime/models/prayer_day.dart';
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
  }) async {
    return PrayerFetchResult(
      days: [
        for (var offset = -pastDays; offset <= futureDays; offset++)
          PrayerDay(
            date: centerDay.add(Duration(days: offset)),
            fajr: '05:00',
            sunrise: '06:30',
            zuhr: '12:30',
            asr: '15:30',
            maghrib: '18:30',
            isha: '20:00',
            tahajjud: '02:30',
          ),
      ],
      timeZone: city.timeZone,
    );
  }
}

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

Widget _app() => PrayerTimeApp(
  appState: AppState(
    api: _InstantFakeApi(),
    notifications: NoopNotificationService(),
    connectivity: const _AlwaysOnline(),
  ),
);

void main() {
  testWidgets('a fresh install lands in setup, not the app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Step one is the language picker — everything after it is read in
    // whatever language is chosen here. With nothing stored yet the app
    // follows the test environment's own locale, hence the English chrome
    // around a list that names each language in itself.
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Prayer'), findsNothing);
  });

  testWidgets('walking the steps through to the end opens the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Six steps: language, theme, city, method, madhab, notifications.
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Prayer'), findsOneWidget);
  });

  testWidgets('an install that predates setup is left alone', (tester) async {
    // No 'onboarding_done', but settings on disk: someone who has been
    // using the app since before this flow existed.
    SharedPreferences.setMockInitialValues({'locale': 'ru'});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
  });
}
