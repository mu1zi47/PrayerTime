import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prayertime/screens/prayer_calendar_screen.dart';
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

    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(find.text('$lastDay'), findsOneWidget);
  });

  testWidgets('the column headings stay put while the days scroll', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();

    // The month selector and column headings stay outside the table scroll.
    final monthLabel = find.textContaining('${DateTime.now().year}');
    expect(monthLabel, findsOneWidget);
    expect(find.text('Фаджр'), findsOneWidget);

    await tester.drag(find.text('00:04').first, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(monthLabel, findsOneWidget);
    expect(find.text('Фаджр'), findsOneWidget);
    expect(find.text('Времена намазов'), findsOneWidget);
  });

  testWidgets('month arrows and swipes stay inside the monthly schedule', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
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

    // Arrows reach both earlier months; a drag does not pop the screen.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left_rounded).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text(label(DateTime(now.year, now.month - 1))), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Времена намазов'), findsOneWidget);
    expect(find.text(label(DateTime(now.year, now.month - 1))), findsOneWidget);
  });

  testWidgets('edge and predictive back gestures never change the month', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 700);
    tester.view.systemGestureInsets = const FakeViewPadding(
      left: 24,
      right: 24,
    );
    addTearDown(tester.view.reset);
    await _pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final label = DateLabels.monthYearLabel(
      lookupAppLocalizations(const Locale('ru')),
      DateTime(now.year, now.month),
    );
    await tester.dragFrom(const Offset(2, 350), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text(label), findsOneWidget);
    await tester.dragFrom(const Offset(798, 350), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text(label), findsOneWidget);

    Future<void> backGesture(String method, [double? progress]) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(
            method,
            progress == null
                ? null
                : {
                    'touchOffset': <double>[5 + progress * 200, 350],
                    'progress': progress,
                    'swipeEdge': 0,
                  },
          ),
        ),
        (_) {},
      );
      await tester.pumpAndSettle();
    }

    await backGesture('startBackGesture', 0);
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<NeverScrollableScrollPhysics>(),
    );
    await tester.dragFrom(
      tester.getCenter(find.byType(PageView)),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    await backGesture('updateBackGestureProgress', .4);
    await backGesture('cancelBackGesture');
    expect(find.text(label), findsOneWidget);
    expect(tester.widget<PageView>(find.byType(PageView)).physics, isNull);
    await backGesture('startBackGesture', 0);
    await backGesture('updateBackGestureProgress', .6);
    await backGesture('commitBackGesture');
    expect(find.text('Времена намазов'), findsNothing);
  });

  testWidgets(
    'home calendar action is below the monthly schedule and opens the calendar',
    (tester) async {
      await _pumpApp(tester);
      final calendar = find.byKey(const ValueKey('home-prayer-calendar'));
      await tester.scrollUntilVisible(
        calendar,
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(calendar).dy,
        greaterThan(tester.getBottomLeft(find.text('Расписание на месяц')).dy),
      );
      await tester.tap(calendar);
      await tester.pumpAndSettle();
      expect(find.byType(PrayerCalendarScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a month is fetched once and then read from cache', (
    tester,
  ) async {
    final api = _CountingApi();
    await _pumpApp(tester, api);

    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Расписание на месяц'));
    await tester.pumpAndSettle();
    expect(api.monthFetches, 1);

    // Leaving and coming back is served from memory.
    await tester.tap(find.byType(ScreenBackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Расписание на месяц'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
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

  // The month action sits after the prayer list, including on narrow phones.
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('the home header fits at ${width.toInt()}dp', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(width, 720);
      addTearDown(tester.view.reset);

      await _pumpApp(tester);

      await tester.scrollUntilVisible(
        find.text('Расписание на месяц'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Расписание на месяц').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Расписание на месяц')).dy,
        greaterThan(tester.getBottomLeft(find.text('Иша')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
