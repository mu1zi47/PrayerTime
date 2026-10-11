import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/theme/app_theme.dart';

void main() {
  testWidgets(
    'interior swipe follows the finger; system edges remain excluded',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              systemGestureInsets: const EdgeInsets.fromLTRB(40, 0, 40, 32),
            ),
            child: child!,
          ),
          home: const Scaffold(body: Center(child: Text('Root'))),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('Previous'))),
        ),
      );
      await tester.pumpAndSettle();
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: PageView(
              children: const [
                Center(child: Text('Current')),
                Center(child: Text('Internal page')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The screen stays put when a gesture starts in the OS edge margin.
      await tester.dragFrom(const Offset(2, 200), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Current'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(PageView)).dx, 0);
      await tester.dragFrom(const Offset(30, 200), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Current'), findsOneWidget);
      // Leftward movement still belongs to the internal pager.
      await tester.dragFrom(const Offset(600, 200), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Internal page'), findsOneWidget);
      // Back works from inside the page, including over a horizontal pager.
      final cancel = await tester.startGesture(const Offset(150, 200));
      await cancel.moveBy(const Offset(25, 0));
      await cancel.moveBy(const Offset(75, 0));
      await tester.pump();
      expect(tester.getTopLeft(find.byType(PageView)).dx, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 500));
      await cancel.up();
      await tester.pumpAndSettle();
      expect(find.text('Internal page'), findsOneWidget);
      expect(tester.getTopLeft(find.byType(PageView)).dx, 0);

      final back = await tester.startGesture(const Offset(150, 200));
      await back.moveBy(const Offset(25, 0));
      await back.moveBy(const Offset(575, 0));
      await tester.pump();
      await back.up();
      await tester.pumpAndSettle();
      expect(find.text('Current'), findsNothing);
      expect(find.text('Previous'), findsOneWidget);

      await tester.dragFrom(const Offset(150, 200), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isFalse);
    },
  );
}
