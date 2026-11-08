import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_cache_store.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

PrayerDay day(DateTime date) => PrayerDay(
  date: date,
  fajr: '05:00',
  sunrise: '06:00',
  zuhr: '12:00',
  asr: '15:00',
  maghrib: '18:00',
  isha: '20:00',
  tahajjud: '03:00',
);

class MemoryCache extends PrayerCacheStore {
  @override
  Future<List<PrayerDay>?> loadMonth(String key) async => null;
  @override
  Future<void> saveMonth({
    required String key,
    required List<PrayerDay> days,
  }) async {}
}

class GateApi extends PrayerTimesApi {
  final requests =
      <({int year, int month, Completer<PrayerFetchResult> result})>[];
  @override
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required int year,
    required int month,
    String? tune,
  }) {
    final result = Completer<PrayerFetchResult>();
    requests.add((year: year, month: month, result: result));
    return result.future;
  }
}

class ImmediateApi extends PrayerTimesApi {
  var calls = 0;
  @override
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required int year,
    required int month,
    String? tune,
  }) async {
    calls++;
    return PrayerFetchResult(
      days: [day(DateTime(year, month))],
      timeZone: 'Asia/Tashkent',
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'concurrent month readers share one request and retry after failure',
    () async {
      final api = GateApi();
      final state = AppState(
        api: api,
        cache: MemoryCache(),
        notifications: NoopNotificationService(),
      );
      addTearDown(state.dispose);
      final first = state.monthDays(2026, 11);
      final second = state.monthDays(2026, 11);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(1));
      final failure = Future.wait([
        expectLater(first, throwsStateError),
        expectLater(second, throwsStateError),
      ]);
      api.requests.single.result.completeError(StateError('offline'));
      await failure;
      final retry = state.monthDays(2026, 11);
      await Future<void>.delayed(Duration.zero);
      expect(api.requests, hasLength(2));
      api.requests.last.result.complete(
        PrayerFetchResult(
          days: [day(DateTime(2026, 11))],
          timeZone: 'Asia/Tashkent',
        ),
      );
      expect(await retry, hasLength(1));
      expect(await state.monthDays(2026, 11), hasLength(1));
      expect(api.requests, hasLength(2));
    },
  );

  test(
    'month memory cache evicts old entries instead of growing indefinitely',
    () async {
      final api = ImmediateApi();
      final state = AppState(
        api: api,
        cache: MemoryCache(),
        notifications: NoopNotificationService(),
      );
      addTearDown(state.dispose);
      for (var month = 1; month <= 13; month++) {
        await state.monthDays(2026, month);
      }
      expect(api.calls, 13);
      await state.monthDays(2026, 1);
      expect(api.calls, 14);
    },
  );

  test('simultaneous disk writes preserve all four cached months', () async {
    const cache = PrayerCacheStore();
    await Future.wait([
      for (var month = 1; month <= 4; month++)
        cache.saveMonth(key: '$month', days: [day(DateTime(2026, month))]),
    ]);
    for (var month = 1; month <= 4; month++) {
      expect(
        (await cache.loadMonth('$month'))!.single.date,
        DateTime(2026, month),
      );
    }
  });

  test(
    'year-boundary requests run together and return a sorted date window',
    () async {
      final api = GateApi();
      final result = api.fetchDaysWindow(
        city: City.fromJson({
          'id': 'test',
          'englishCity': 'Test',
          'englishCountry': 'Test',
          'latitude': 41.3,
          'longitude': 69.2,
          'timeZone': 'Asia/Tashkent',
        }),
        methodCode: 1,
        school: 1,
        centerDay: DateTime(2026, 12, 31),
        pastDays: 3,
        futureDays: 3,
      );
      expect(api.requests, hasLength(2));
      api.requests.last.result.complete(
        PrayerFetchResult(
          days: [day(DateTime(2027, 1, 3)), day(DateTime(2027, 1, 1))],
          timeZone: 'Asia/Tashkent',
        ),
      );
      api.requests.first.result.complete(
        PrayerFetchResult(
          days: [day(DateTime(2026, 12, 31)), day(DateTime(2026, 12, 1))],
          timeZone: 'Asia/Tashkent',
        ),
      );
      final fetched = await result;
      expect(fetched.days.map((d) => d.date), [
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
        DateTime(2027, 1, 3),
      ]);
    },
  );

  test(
    'an empty month response terminates with a recoverable API error',
    () async {
      final api = GateApi();
      final result = api.fetchDaysWindow(
        city: const City(
          id: 'test',
          englishCity: 'Test',
          englishCountry: 'Test',
          latitude: 41.3,
          longitude: 69.2,
          timeZone: 'Asia/Tashkent',
        ),
        methodCode: 1,
        school: 1,
        centerDay: DateTime(2026, 11, 8),
        pastDays: 3,
        futureDays: 3,
      );
      final check = expectLater(result, throwsA(isA<PrayerApiException>()));
      expect(api.requests, hasLength(1));
      api.requests.single.result.complete(
        const PrayerFetchResult(days: [], timeZone: ''),
      );
      await check;
      expect(api.requests, hasLength(1));
    },
  );

  test('disposing during startup stops late state updates', () async {
    final installed = Completer<InstallTimes?>();
    final state = AppState(
      notifications: NoopNotificationService(),
      installTimes: () => installed.future,
    );
    final initialization = state.init();
    await Future<void>.delayed(Duration.zero);
    state.dispose();
    installed.complete(null);
    await initialization;
  });

  testWidgets('non-overlapping screen panels share a backdrop operation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScreenContentInset(
          child: Column(
            children: [
              GlassPanel(child: SizedBox(width: 200, height: 100)),
              SizedBox(height: 16),
              GlassPanel(child: SizedBox(width: 200, height: 100)),
            ],
          ),
        ),
      ),
    );
    final filters = tester
        .renderObjectList<RenderBackdropFilter>(find.byType(BackdropFilter))
        .toList();
    expect(filters, hasLength(2));
    expect(filters.first.backdropKey, isNotNull);
    expect(filters.first.backdropKey, same(filters.last.backdropKey));
  });
}
