import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiveglow/l10n/app_localizations.dart';
import 'package:fiveglow/models/prayer_day.dart';
import 'package:fiveglow/models/prayer_log_status.dart';
import 'package:fiveglow/widgets/icon_badge.dart';
import 'package:fiveglow/screens/home_screen.dart';
import 'package:fiveglow/services/notification_service.dart';
import 'package:fiveglow/state/app_state.dart';
import 'package:fiveglow/theme/app_theme.dart';
import 'package:fiveglow/widgets/ambient_surface.dart';
import 'package:fiveglow/widgets/app_tap.dart';

class _EveningState extends AppState {
  _EveningState() : super(notifications: NoopNotificationService());

  PrayerLogStatus? status;
  @override
  PrayerLogStatus? prayerStatusFor(DateTime date, String key) => status;

  @override
  void setPrayerStatus(
    DateTime date,
    String prayerKey,
    PrayerLogStatus? value,
  ) {
    status = status == value ? null : value;
    notifyListeners();
  }

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

Widget _app(_EveningState state, {double textScale = 1}) => MaterialApp(
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
    child: AmbientScaffold(body: HomeScreen(appState: state)),
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
    expect(find.text('05:43'), findsNothing);
    expect(find.text('10:04:00'), findsOneWidget);
    state.now = state.now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('10:03:59'), findsOneWidget);
    final today = find.byKey(const ValueKey('today-prayers-panel'));
    expect(
      find.descendant(of: today, matching: find.text('05:43')),
      findsNothing,
    );
    expect(
      tester
          .getTopRight(find.byKey(const ValueKey('next-prayer-countdown')))
          .dx,
      closeTo(372, .1),
    );
    await tester.ensureVisible(find.text('Расписание'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tomorrow-prayer-panel')), findsNothing);
    final monthAction = find.ancestor(
      of: find.text('Расписание'),
      matching: find.byType(AppTap),
    );
    expect(
      tester.getBottomLeft(monthAction).dy,
      lessThan(tester.getTopLeft(today).dy),
    );
    expect(find.text('8 ноября'), findsNothing);
    expect(find.byKey(const ValueKey('prayer-divider-maghrib')), findsOneWidget);
    expect(find.byKey(const ValueKey('prayer-divider-isha')), findsNothing);
    expect(find.byKey(const ValueKey('prayer-divider-asr')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home sections have padding while action row stays edge to edge',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final state = _EveningState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Ташкент')).dx, 18);
      final summary = find.byKey(const ValueKey('next-prayer-summary'));
      expect(tester.getTopLeft(summary).dx, 18);
      expect(tester.getSize(summary).width, 354);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 400.0]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets('home uses full viewport at $width dp and scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.reset);
        final state = _EveningState();
        addTearDown(state.dispose);
        await tester.pumpWidget(_app(state, textScale: scale));
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(ListView)).height, 844);
        await tester.drag(find.byType(ListView), const Offset(0, -1400));
        await tester.pumpAndSettle();
        final isha = find.text('18:32');
        expect(isha.hitTestable(), findsOneWidget);
        expect(tester.getBottomLeft(isha).dy, lessThan(820));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('schedule and calendar are separate squares above prayers', (
    tester,
  ) async {
    final state = _EveningState();
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    final actions = find.byKey(const ValueKey('home-schedule-actions'));
    await tester.ensureVisible(actions);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: actions, matching: find.byType(GlassPanel)),
      findsNWidgets(5),
    );
    final monthly = find.byKey(const ValueKey('home-monthly-times'));
    final calendar = find.byKey(const ValueKey('home-prayer-calendar'));
    expect(tester.getSize(monthly), const Size(140, 140));
    expect(tester.getTopLeft(monthly).dx, 18);
    expect(tester.getSize(calendar), tester.getSize(monthly));
    expect(tester.getTopLeft(calendar).dx - tester.getTopRight(monthly).dx, 6);
    expect(tester.getTopLeft(monthly).dy, tester.getTopLeft(calendar).dy);
    expect(
      tester.getBottomLeft(actions).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('today-prayers-panel'))).dy,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-prayers-panel')),
        matching: find.byType(GlassPanel),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'action content has edge padding while viewport clips at screen edge',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final state = _EveningState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state, textScale: 1.8));
      await tester.pumpAndSettle();
      final actions = find.byKey(const ValueKey('home-schedule-actions'));
      await tester.ensureVisible(actions);
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('home-monthly-times'));
      final last = find.byKey(const ValueKey('home-settings'));
      expect(tester.getTopLeft(actions).dx, 0);
      expect(tester.getSize(actions).width, 390);
      expect(tester.getTopLeft(first).dx, 18);

      await tester.drag(actions, const Offset(-50, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(first).dx, lessThan(0));

      await tester.drag(actions, const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(tester.getTopRight(last).dx, closeTo(372, .1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tools collapse on a short page and return at the top', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(tester.view.reset);
    final state = _EveningState();
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    final scroll = find.byKey(const ValueKey('home-scroll'));
    final reveal = find.byKey(const ValueKey('home-actions-reveal'));
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first,
        )
        .position;
    expect(position.maxScrollExtent, 0);
    expect(tester.getSize(reveal).height, greaterThan(0));
    final prayers = find.byKey(const ValueKey('today-prayers-panel'));
    final map = find.byKey(const ValueKey('home-nearby-mosque'));
    expect(
      tester.getTopLeft(map).dy,
      greaterThan(tester.getBottomLeft(prayers).dy),
    );

    final fullHeight = tester.getSize(reveal).height;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('next-prayer-summary'))),
    );
    // Establish the vertical gesture, then verify individual pixel deltas.
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump();
    final firstHeight = tester.getSize(reveal).height;
    final firstButtonTop = tester
        .getTopLeft(find.byKey(const ValueKey('home-monthly-times')))
        .dy;
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    final partialHeight = tester.getSize(reveal).height;
    expect(partialHeight, closeTo(firstHeight - 30, .1));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-monthly-times'))).dy,
      closeTo(firstButtonTop - 30, .1),
    );
    expect(partialHeight, inExclusiveRange(0, fullHeight));
    // The row moves above its layout boundary instead of clipping there.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-monthly-times'))).dy,
      lessThan(tester.getTopLeft(reveal).dy),
    );
    expect(
      find.descendant(of: reveal, matching: find.byType(SizeTransition)),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getSize(reveal).height, partialHeight);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, fullHeight);
    expect(position.pixels, 0);
    // Collapse past halfway and check that release completes the collapse.
    final close = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('next-prayer-summary'))),
    );
    await close.moveBy(Offset(0, -fullHeight * .8));
    await tester.pump();
    await close.up();
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, 0);

    // A reverse drag follows the finger too, without reopening in one jump.
    final reverse = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('next-prayer-summary'))),
    );
    await reverse.moveBy(const Offset(0, 24));
    await tester.pump();
    final beforeReveal = tester.getSize(reveal).height;
    await reverse.moveBy(const Offset(0, 12));
    await tester.pump();
    expect(tester.getSize(reveal).height, closeTo(beforeReveal + 12, .1));
    await reverse.up();
    await tester.pumpAndSettle();

    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, 0);
    expect(find.text('Расписание').hitTestable(), findsNothing);
    expect(position.pixels, 0);

    await tester.drag(scroll, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(tester.getSize(reveal).height, greaterThan(0));
    expect(find.text('Расписание').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tools stay hidden until the vertical scroll returns to the top',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 500);
      addTearDown(tester.view.reset);
      final state = _EveningState();
      addTearDown(state.dispose);
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('home-scroll'));
      final reveal = find.byKey(const ValueKey('home-actions-reveal'));
      await tester.drag(scroll, const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(find.text('Расписание').hitTestable(), findsNothing);
      await tester.drag(scroll, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(find.text('Расписание').hitTestable(), findsNothing);
      await tester.drag(scroll, const Offset(0, 1600));
      await tester.pumpAndSettle();
      expect(tester.getSize(reveal).height, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('only the prayer button toggles a mark without a sheet', (
    tester,
  ) async {
    final state = _EveningState();
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    final time = find.text('15:30');
    await tester.ensureVisible(time);
    await tester.pumpAndSettle();
    await tester.drag(time, const Offset(-80, 0));
    await tester.pumpAndSettle();
    expect(find.text('Как прошёл Аср?'), findsNothing);
    await tester.tap(time);
    await tester.pumpAndSettle();
    expect(state.status, isNull);
    final button = find.byKey(const ValueKey('prayer-mark-asr'));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.status, PrayerLogStatus.onTime);
    expect(find.text('Как прошёл Аср?'), findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.status, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('future prayer button is disabled on home', (tester) async {
    final state = _EveningState()..now = DateTime.utc(2026, 11, 8, 18, 31);
    addTearDown(state.dispose);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('prayer-mark-isha'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.status, isNull);
    state.now = DateTime.utc(2026, 11, 8, 18, 32);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.status, PrayerLogStatus.onTime);
  });

  for (final width in [360.0, 400.0]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'all prayer rows including sunrise share geometry at $width/$scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 1600);
          addTearDown(tester.view.reset);
          final state = _EveningState();
          addTearDown(state.dispose);
          await tester.pumpWidget(_app(state, textScale: scale));
          await tester.pumpAndSettle();
          final reference = find.byKey(const ValueKey('prayer-row-fajr'));
          final height = tester.getSize(reference).height;
          final timeRight = tester.getTopRight(find.text('05:42')).dx;
          for (final entry in [
            ('fajr', '05:42'),
            ('sunrise', '07:02'),
            ('zuhr', '12:07'),
            ('asr', '15:30'),
            ('maghrib', '17:15'),
            ('isha', '18:32'),
          ]) {
            final row = find.byKey(ValueKey('prayer-row-${entry.$1}'));
            expect(tester.getSize(row).height, height, reason: entry.$1);
            expect(
              tester.getTopRight(find.text(entry.$2)).dx,
              closeTo(timeRight, .1),
              reason: entry.$1,
            );
            final icon = find.descendant(
              of: row,
              matching: find.byType(IconBadge),
            );
            expect(
              tester.getCenter(icon).dy,
              closeTo(tester.getCenter(row).dy, .1),
            );
            if (entry.$1 != 'sunrise') {
              final surface = find.descendant(
                of: row,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget.key ==
                      const ValueKey('prayer-swipe-preview-unread'),
                ),
              );
              expect(
                tester.getCenter(surface).dy,
                closeTo(tester.getCenter(icon).dy, .1),
              );
              expect(
                tester.getTopLeft(icon).dx - tester.getTopLeft(row).dx,
                closeTo(
                  tester.getTopRight(row).dx - tester.getTopRight(surface).dx,
                  .1,
                ),
              );
            }
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
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
    await tester.ensureVisible(find.text('Расписание'));
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
