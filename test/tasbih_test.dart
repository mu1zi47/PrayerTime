import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/models/tasbih_counter.dart';
import 'package:prayertime/screens/tasbih_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('33 and 99 wrap the round while preserving every tap', () async {
    final counter = await TasbihCounter.load();
    addTearDown(counter.dispose);
    for (var i = 0; i < 33; i++) {
      counter.increment();
    }
    expect(counter.current, 0);
    expect(counter.total, 33);
    counter.increment();
    expect(counter.current, 1);
    counter.setLimit(99);
    expect(counter.current, 0);
    for (var i = 0; i < 100; i++) {
      counter.increment();
    }
    expect(counter.current, 1);
    expect(counter.total, 134);
    await counter.saved;
  });

  test(
    'unlimited, mode and totals survive reopening even with queued writes',
    () async {
      final counter = await TasbihCounter.load();
      addTearDown(counter.dispose);
      counter.setLimit(0);
      for (var i = 0; i < 150; i++) {
        counter.increment();
      }
      final restored = await TasbihCounter.load();
      addTearDown(restored.dispose);
      expect(restored.limit, 0);
      expect(restored.current, 150);
      expect(restored.total, 150);
      restored.increment();
      restored.clear();
      final cleared = await TasbihCounter.load();
      addTearDown(cleared.dispose);
      expect(cleared.limit, 0);
      expect(cleared.current, 0);
      expect(cleared.total, 0);
    },
  );

  testWidgets('counter wraps, restores, and requires confirmation to clear', (
    tester,
  ) async {
    Widget screen() => const MaterialApp(
      locale: Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TasbihScreen(),
    );
    await tester.pumpWidget(screen());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    final modes = [
      33,
      99,
      0,
    ].map((n) => find.byKey(ValueKey('tasbih-mode-$n'))).toList();
    final before = modes.map(tester.getRect).toList();
    await tester.tap(find.text('99'));
    await tester.pumpAndSettle();
    expect(modes.map(tester.getRect).toList(), before);
    await tester.tap(find.text('33'));
    await tester.pumpAndSettle();
    expect(modes.map(tester.getRect).toList(), before);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .strokeCap,
      StrokeCap.round,
    );
    await tester.tap(find.byKey(const ValueKey('tasbih-tap')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      inExclusiveRange(0, 1 / 33),
    );
    await tester.pumpAndSettle();
    for (var i = 1; i < 34; i++) {
      await tester.tap(find.byKey(const ValueKey('tasbih-tap')));
      await tester.pump();
    }
    String value(String key) =>
        tester.widget<Text>(find.byKey(ValueKey(key))).data!;
    await tester.pumpAndSettle();
    expect(value('tasbih-current'), '1');
    expect(value('tasbih-total'), '34');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen());
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    expect(value('tasbih-total'), '34');
    await tester.ensureVisible(find.text('Очистить'));
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    final cancelPosition = tester.getCenter(find.text('Отмена'));
    final clearPosition = tester.getCenter(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Очистить'),
      ),
    );
    expect(cancelPosition.dy, closeTo(clearPosition.dy, 1));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(value('tasbih-total'), '34');
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Очистить'),
      ),
    );
    await tester.pumpAndSettle();
    expect(value('tasbih-current'), '0');
    expect(value('tasbih-total'), '0');
  });
}
