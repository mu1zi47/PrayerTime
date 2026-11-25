import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fiveglow/main.dart';
import 'package:fiveglow/screens/home_screen.dart';
import 'package:fiveglow/screens/names_screen.dart';
import 'package:fiveglow/screens/tasbih_screen.dart';
import 'package:fiveglow/screens/settings_screen.dart';
import 'package:fiveglow/models/prayer_day.dart';
import 'package:fiveglow/services/connectivity_service.dart';
import 'package:fiveglow/services/notification_service.dart';
import 'package:fiveglow/services/prayer_times_api.dart';
import 'package:fiveglow/state/app_state.dart';

class _InstantFakeApi extends PrayerTimesApi {
  _InstantFakeApi({this.fail = false});
  final bool fail;

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
    if (fail) throw StateError('FiveGlow are unavailable');
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

  testWidgets(
    'Home opens settings and tools and returns through route history',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        FiveGlowApp(
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

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Ещё'), findsNothing);

      await tester.ensureVisible(find.byKey(const ValueKey('home-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      final names = find.byKey(const ValueKey('home-allah-names'));
      await tester.ensureVisible(names);
      await tester.pumpAndSettle();
      await tester.tap(names);
      await tester.pumpAndSettle();
      expect(find.byType(NamesScreen), findsOneWidget);
      // First Back dismisses the existing names disclaimer.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(NamesScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      final tasbih = find.byKey(const ValueKey('home-tasbih'));
      await tester.ensureVisible(tasbih);
      await tester.pumpAndSettle();
      await tester.tap(tasbih);
      await tester.pumpAndSettle();
      expect(find.byType(TasbihScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('home-mosque-map')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tools and settings remain reachable without prayer times', (
    tester,
  ) async {
    await tester.pumpWidget(
      FiveGlowApp(
        appState: AppState(
          api: _InstantFakeApi(fail: true),
          notifications: NoopNotificationService(),
          connectivity: const _AlwaysOnline(),
          installTimes: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-monthly-times')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-prayer-calendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-allah-names')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-mosque-map')), findsNothing);
    expect(find.byKey(const ValueKey('home-tasbih')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
