import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/data/date_labels.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/main.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/widgets/screen_back_button.dart';

// Same flat schedule for every day, so a time found on screen says which
// screen is up rather than which day is being read.
PrayerDay _day(DateTime date) => PrayerDay(
  date: date,
  fajr: '00:01',
  sunrise: '00:02',
  zuhr: '00:03',
  asr: '00:04',
  maghrib: '00:05',
  isha: '00:06',
  tahajjud: '00:00',
);

class _FakeApi extends PrayerTimesApi {
  @override
  Future<PrayerFetchResult> fetchDaysWindow({
    required City city,
    required int methodCode,
    required int school,
    required DateTime centerDay,
    required int pastDays,
    required int futureDays,
    String? tune,
  }) async => PrayerFetchResult(
    days: [
      for (var offset = -pastDays; offset <= futureDays; offset++)
        _day(centerDay.add(Duration(days: offset))),
    ],
    timeZone: city.timeZone,
  );

  @override
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required String? tune,
    required int year,
    required int month,
  }) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return PrayerFetchResult(
      days: [
        for (var day = 1; day <= daysInMonth; day++)
          _day(DateTime(year, month, day)),
      ],
      timeZone: city.timeZone,
    );
  }
}

/// Counts month fetches, so a test can tell a cache hit from a request.
class _CountingApi extends _FakeApi {
  int monthFetches = 0;

  @override
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required String? tune,
    required int year,
    required int month,
  }) {
    monthFetches++;
    return super.fetchMonth(
      city: city,
      methodCode: methodCode,
      school: school,
      tune: tune,
      year: year,
      month: month,
    );
  }
}

/// Stands in for having no connection at all on the month endpoint.
class _NoMonthApi extends _FakeApi {
  @override
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required String? tune,
    required int year,
    required int month,
  }) async => throw const PrayerApiException(PrayerApiError.noConnection);
}

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

Future<void> _pumpApp(WidgetTester tester, [PrayerTimesApi? api]) async {
  await tester.pumpWidget(
    PrayerTimeApp(
      appState: AppState(
        api: api ?? _FakeApi(),
        notifications: NoopNotificationService(),
        connectivity: const _AlwaysOnline(),
        installTimes: () async => null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // 'onboarding_done' skips the first-run setup flow — see
    // OnboardingScreen.
    SharedPreferences.setMockInitialValues({
      'locale': 'ru',
      'onboarding_done': true,
    });
  });

  testWidgets('the month button opens a whole month of times', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();

    expect(find.text('Времена намазов'), findsOneWidget);
    // A row per day of the month — the list is lazy, so only the ones on
    // screen are built.
    expect(find.text('00:04'), findsWidgets);
    // The last day of the month is in there too, well past the ±7 days the
    // home screen itself holds.
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    await tester.scrollUntilVisible(
      find.text('$lastDay'),
      200,
      // The month's own vertical scroll, not the pager around it.
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('$lastDay'), findsOneWidget);
  });

  testWidgets('the column headings stay put while the days scroll', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();

    // The month and its arrows scroll away with the list; the title bar and
    // the headings above it don't.
    final monthLabel = find.textContaining('${DateTime.now().year}');
    expect(monthLabel, findsOneWidget);
    expect(find.text('Фаджр'), findsOneWidget);

    await tester.drag(find.text('00:04').first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(monthLabel, findsNothing);
    expect(find.text('Фаджр'), findsOneWidget);
    expect(find.text('Времена намазов'), findsOneWidget);
  });

  testWidgets('swiping moves between the three months', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    String label(DateTime month) => DateLabels.monthYearLabel(
      lookupAppLocalizations(const Locale('ru')),
      month,
    );

    expect(find.text(label(DateTime(now.year, now.month))), findsOneWidget);

    // Left: the month ahead.
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(label(DateTime(now.year, now.month + 1))), findsOneWidget);

    // Back past this month to the one behind it, and no further — the pager
    // holds exactly the three months the arrows reach.
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(label(DateTime(now.year, now.month - 1))), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(label(DateTime(now.year, now.month - 1))), findsOneWidget);
  });

  testWidgets('a month is fetched once and then read from cache', (
    tester,
  ) async {
    final api = _CountingApi();
    await _pumpApp(tester, api);

    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();
    expect(api.monthFetches, 1);

    // Leaving and coming back is served from memory.
    await tester.tap(find.byType(ScreenBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();
    expect(api.monthFetches, 1);

    // And a later run reads it off disk: a fresh AppState whose month
    // endpoint always fails still serves the month, so the screen opens
    // with no connection too.
    final laterRun = AppState(
      api: _NoMonthApi(),
      notifications: NoopNotificationService(),
      connectivity: const _AlwaysOnline(),
      installTimes: () async => null,
    );
    final now = DateTime.now();
    final stored = await laterRun.monthDays(now.year, now.month);
    expect(stored, hasLength(DateTime(now.year, now.month + 1, 0).day));
  });

  // The month button's label is long enough to crowd the date beside it —
  // this is what keeps that row from overflowing on a narrow phone.
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('the home header fits at ${width.toInt()}dp', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(width, 720);
      addTearDown(tester.view.reset);

      await _pumpApp(tester);

      expect(find.text('Расписание на месяц'), findsOneWidget);
    });
  }
}
