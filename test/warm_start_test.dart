import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';

/// Never completes — stands in for a slow network, so the test can tell
/// "served from cache" apart from "served from the fetch".
class _HangingApi extends PrayerTimesApi {
  @override
  Future<PrayerFetchResult> fetchDaysWindow({
    required City city,
    required int methodCode,
    required int school,
    required DateTime centerDay,
    required int pastDays,
    required int futureDays,
    String? tune,
  }) => Completer<PrayerFetchResult>().future;
}

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a cold start paints the cached schedule before the fetch lands',
    () async {
      final today = DateTime.now();
      final cached = [
        for (var offset = -1; offset <= 1; offset++)
          {
            'date': today.add(Duration(days: offset)).toIso8601String(),
            'fajr': '05:00',
            'sunrise': '06:30',
            'zuhr': '12:30',
            'asr': '15:30',
            'maghrib': '18:30',
            'isha': '20:00',
            'tahajjud': '02:30',
          },
      ];
      SharedPreferences.setMockInitialValues({
        'locale': 'ru',
        // Matches PrayerCacheStore.signatureFor for the default city/method/madhab.
        'prayer_cache_signature': 'tashkent|uzbekistan|hanafi',
        'prayer_cache_days': jsonEncode(cached),
      });

      final appState = AppState(
        api: _HangingApi(),
        notifications: NoopNotificationService(),
        connectivity: const _AlwaysOnline(),
      );
      addTearDown(appState.dispose);

      // init() itself never returns here — it awaits the fetch, which is the
      // whole point of the hanging API. What matters is that the schedule
      // reaches listeners before that.
      final servedFromCache = Completer<void>();
      appState.addListener(() {
        if (appState.days.isNotEmpty && !servedFromCache.isCompleted) {
          servedFromCache.complete();
        }
      });
      unawaited(appState.init());
      await servedFromCache.future.timeout(const Duration(seconds: 5));

      expect(
        appState.days,
        isNotEmpty,
        reason: 'cache should have been served',
      );
      expect(appState.isLoadingDays, isFalse);
      expect(appState.daysError, isNull);
    },
  );
}
