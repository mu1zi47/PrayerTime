import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/main.dart';
import 'package:prayertime/screens/home_screen.dart';
import 'package:prayertime/screens/more_screen.dart';
import 'package:prayertime/screens/settings_screen.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

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

// The real ConnectivityService talks to a platform channel (connectivity_plus)
// that has no test-environment stub and can hang indefinitely waiting on a
// response instead of failing fast — always-online here keeps this test
// deterministic, the same reason _InstantFakeApi/NoopNotificationService
// exist below.
class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

void main() {
  setUp(() {
    // AppState.init() reads persisted settings on startup — keep tests
    // isolated from real device storage and from each other. Locale is
    // pinned explicitly since AppState otherwise follows the system locale
    // on a fresh install (see AppState._restore), which this test's
    // hardcoded Russian text assertions don't want varying by test-runner
    // environment.
    // 'onboarding_done' skips the first-run setup flow — see
    // OnboardingScreen; these tests are about what comes after it.
    SharedPreferences.setMockInitialValues({
      'locale': 'ru',
      'onboarding_done': true,
    });
  });

  testWidgets('App renders the home screen and switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PrayerTimeApp(
        appState: AppState(
          api: _InstantFakeApi(),
          notifications: NoopNotificationService(),
          connectivity: const _AlwaysOnline(),
          // No platform here to report install times; left unset, the
          // plugin call would never answer.
          installTimes: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
    expect(find.text('Настройки'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final width = tester.getSize(find.byType(PageView)).width;
    expect(
      tester.getTopLeft(find.byType(HomeScreen)).dx,
      inExclusiveRange(-width, 0),
    );
    expect(
      tester.getTopLeft(find.byType(SettingsScreen)).dx,
      inExclusiveRange(0, width),
    );
    expect(find.byType(MoreScreen), findsNothing);
    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsWidgets);
    expect(ambientPosition.value, AmbientNavigationObserver.positions[2]);
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(find.byType(SettingsScreen)).dx,
      inExclusiveRange(0, width),
    );
    expect(
      tester.getTopLeft(find.byType(HomeScreen)).dx,
      inExclusiveRange(-width, 0),
    );
    expect(find.byType(MoreScreen), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(HomeScreen)).dx, 0);
    expect(ambientPosition.value, AmbientNavigationObserver.positions[0]);

    // Normal swiping still follows the original tab order after the shortcut.
    await tester.dragFrom(const Offset(700, 70), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(MoreScreen)).dx, 0);
    expect(ambientPosition.value, AmbientNavigationObserver.positions[1]);
  });
}
