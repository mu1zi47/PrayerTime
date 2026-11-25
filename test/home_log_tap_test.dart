import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fiveglow/models/prayer_log_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fiveglow/main.dart';
import 'package:fiveglow/models/prayer_day.dart';
import 'package:fiveglow/services/connectivity_service.dart';
import 'package:fiveglow/services/notification_service.dart';
import 'package:fiveglow/services/prayer_times_api.dart';
import 'package:fiveglow/state/app_state.dart';

// Every prayer sits just after midnight, so all of them have already passed
// by the time this test runs (whatever the wall clock says) and every row on
// the home screen is loggable.
class _AllPrayersPassedApi extends PrayerTimesApi {
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
            fajr: '00:01',
            sunrise: '00:02',
            zuhr: '00:03',
            asr: '00:04',
            maghrib: '00:05',
            isha: '00:06',
            tahajjud: '00:00',
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

void main() {
  setUp(() {
    // 'onboarding_done' skips the first-run setup flow — see
    // OnboardingScreen; these tests are about what comes after it.
    SharedPreferences.setMockInitialValues({
      'locale': 'ru',
      'onboarding_done': true,
    });
  });

  testWidgets('prayer button saves and clears a mark without a sheet', (
    tester,
  ) async {
    final state = AppState(
      api: _AllPrayersPassedApi(),
      notifications: NoopNotificationService(),
      connectivity: const _AlwaysOnline(),
      installTimes: () async => null,
    );
    await tester.pumpWidget(FiveGlowApp(appState: state));
    await tester.pumpAndSettle();

    // Asr's time, unique on the screen — a plain tap, no swipe.
    await tester.ensureVisible(find.text('00:04'));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('prayer-mark-asr'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.prayerStatusFor(state.cityNow, 'asr'), PrayerLogStatus.onTime);
    expect(find.text('Как прошёл Аср?'), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.prayerStatusFor(state.cityNow, 'asr'), isNull);
  });
}
