import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/main.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';

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
    SharedPreferences.setMockInitialValues({'locale': 'ru'});
  });

  testWidgets('tapping a prayer row opens the log sheet', (tester) async {
    await tester.pumpWidget(
      PrayerTimeApp(
        appState: AppState(
          api: _AllPrayersPassedApi(),
          notifications: NoopNotificationService(),
          connectivity: const _AlwaysOnline(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Asr's time, unique on the screen — a plain tap, no swipe.
    await tester.tap(find.text('00:04'));
    await tester.pumpAndSettle();

    expect(find.text('Как прошёл Аср?'), findsOneWidget);
    expect(find.text('Прочитал вовремя'), findsOneWidget);
  });
}
