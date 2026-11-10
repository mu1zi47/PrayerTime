import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/models/prayer_log_status.dart';
import 'package:prayertime/widgets/icon_badge.dart';
import 'package:prayertime/screens/home_screen.dart';
import 'package:prayertime/screens/more_screen.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/theme/app_theme.dart';
import 'package:prayertime/widgets/ambient_surface.dart';
import 'package:prayertime/widgets/floating_tab_bar.dart';
import 'package:prayertime/widgets/app_tap.dart';

class _EveningState extends AppState {
  _EveningState() : super(notifications: NoopNotificationService());

  PrayerLogStatus? status;
  @override
  PrayerLogStatus? prayerStatusFor(DateTime date, String key) => status;

  DateTime now = DateTime.utc(2026, 11, 8, 19, 39);
  @override
  DateTime get cityNow => now;
  @override
  int get todayIndex => 1;
  @override
  final List<PrayerDay> days = [
    for (var day = 7; day <= 9; day++)
      PrayerDay(
        date: DateTime.utc(2026, 11, day),
        fajr: day == 9 ? '05:43' : '05:42',
        sunrise: '07:02',
        zuhr: '12:07',
        asr: '15:30',
        maghrib: '17:15',
        isha: '18:32',
        tahajjud: '02:30',
      ),
  ];
}

Widget _app(_EveningState state, {bool more = false, double textScale = 1}) =>
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      scrollBehavior: const StableScrollBehavior(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          textScaler: TextScaler.linear(textScale),
        ),
        child: AmbientScaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: more
                    ? MoreScreen(appState: state)
                    : HomeScreen(appState: state),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingTabBar(index: more ? 1 : 0, onSelect: (_) {}),
              ),
            ],
          ),
        ),
      ),
    );

void main() {
  testWidgets('tomorrow appears only in the next-prayer card', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final state = _EveningState();
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    expect(find.text('05:43'), findsOneWidget);
    final today = find.byKey(const ValueKey('today-prayers-panel'));
    expect(
      find.descendant(of: today, matching: find.text('05:43')),
      findsNothing,
    );
    await tester.scrollUntilVisible(find.text('Расписание на месяц'), 150);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tomorrow-prayer-panel')), findsNothing);
    final monthAction = find.ancestor(
      of: find.text('Расписание на месяц'),
      matching: find.byType(AppTap),
    );
    expect(
      tester.getTopLeft(monthAction).dy - tester.getBottomLeft(today).dy,
      closeTo(16, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'city starts exactly where More starts and can scroll above its resting inset',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final state = _EveningState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();
      final city = find.text('Ташкент');
      expect(tester.widget<Text>(city).style!.fontSize, 12.5);
      final start = tester.getTopLeft(city);
      expect(start, const Offset(18, 40));
      await tester.drag(find.byType(ListView), const Offset(0, -12));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(city).dy, lessThan(start.dy));
      expect(city.hitTestable(), findsOneWidget);
      await tester.pumpWidget(_app(state, more: true));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(
          find.descendant(
            of: find.byType(MoreScreen),
            matching: find.text('Ещё'),
          ),
        ),
        start,
      );
      expect(find.text('Календарь намазов'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.8]) {
    testWidgets('scroll viewport ends 16px above nav at text scale $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final state = _EveningState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state, textScale: scale));
      await tester.pumpAndSettle();
      final viewportBottom = tester.getBottomLeft(find.byType(ListView)).dy;
      final navTop = tester
          .getTopLeft(find.byKey(FloatingTabBar.surfaceKey))
          .dy;
      expect(navTop - viewportBottom, closeTo(16, .1));
      await tester.scrollUntilVisible(find.text('Расписание на месяц'), 150);
      await tester.pumpAndSettle();
      expect(find.text('Расписание на месяц').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('schedule and calendar share one panel and one separator', (
    tester,
  ) async {
    final state = _EveningState();
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    final actions = find.byKey(const ValueKey('home-schedule-actions'));
    await tester.scrollUntilVisible(actions, 150);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: actions, matching: find.byType(GlassPanel)),
      findsNothing,
    );
    expect(
      find.descendant(of: actions, matching: find.byType(PanelDivider)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actions, matching: find.text('Расписание на месяц')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: actions, matching: find.text('Календарь намазов')),
      findsOneWidget,
    );
  });

  for (final status in [null, PrayerLogStatus.onTime, PrayerLogStatus.qada]) {
    testWidgets('prayer swipe preview uses transparent tile for $status', (
      tester,
    ) async {
      final state = _EveningState()..status = status;
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();
      final time = find.text('15:30');
      await tester.ensureVisible(time);
      await tester.pumpAndSettle();
      final stack = find.ancestor(of: time, matching: find.byType(Stack)).first;
      final preview = find.descendant(
        of: stack,
        matching: find.byKey(
          ValueKey('prayer-swipe-preview-${status?.name ?? 'unread'}'),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(time));
      await gesture.moveBy(const Offset(-32, 0));
      await tester.pumpAndSettle();
      expect(preview, findsOneWidget);
      final decoration =
          tester.widget<Container>(preview).decoration! as BoxDecoration;
      expect(decoration.color, isNull);
      if (status == null) {
        expect(decoration.gradient, isNull);
      } else {
        expect(decoration.gradient, isA<LinearGradient>());
      }
      expect(decoration.border, isNotNull);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('name number badges share the new surface and center digits', (
    tester,
  ) async {
    for (final number in [1, 88, 100]) {
      await tester.pumpWidget(
        MaterialApp(home: Center(child: NumberBadge(number))),
      );
      final badge = find.byType(NumberBadge);
      final text = find.text('$number');
      expect(tester.getCenter(text), tester.getCenter(badge));
      final surface = tester.widget<Container>(
        find.descendant(of: badge, matching: find.byType(Container)),
      );
      expect((surface.decoration! as BoxDecoration).color, isNull);
      expect(
        (surface.decoration! as BoxDecoration).gradient,
        isA<LinearGradient>(),
      );
    }
  });

  testWidgets('previous-night Isha has no extra panel after midnight', (
    tester,
  ) async {
    final state = _EveningState()..now = DateTime.utc(2026, 11, 8, 0, 30);
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Расписание на месяц'), 150);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('yesterday-prayer-panel')), findsNothing);
    expect(find.textContaining('ВЧЕРА'), findsNothing);
    expect(find.text('Иша'), findsOneWidget);
    final today = find.byKey(const ValueKey('today-prayers-panel'));
    expect(
      find.descendant(of: today, matching: find.text('Иша')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
