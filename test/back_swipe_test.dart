import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/theme/app_theme.dart';

void main() {
  testWidgets(
    'only the system back gesture previews, cancels and pops a route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: AppTheme.light,
          home: const Scaffold(body: Center(child: Text('Root'))),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            key: ValueKey('current-page'),
            body: Center(child: Text('Current')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(150, 200), const Offset(600, 0));
      await tester.pumpAndSettle();
      expect(find.text('Current'), findsOneWidget);
      final initial = tester.getRect(
        find.byKey(const ValueKey('current-page')),
      );

      Future<void> systemGesture(String method, [double? progress]) async {
        final message = const StandardMethodCodec().encodeMethodCall(
          MethodCall(
            method,
            progress == null
                ? null
                : {
                    'touchOffset': <double>[5 + progress * 200, 300],
                    'progress': progress,
                    'swipeEdge': 0,
                  },
          ),
        );
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          message,
          (_) {},
        );
        await tester.pumpAndSettle();
      }

      await systemGesture('startBackGesture', 0);
      await systemGesture('updateBackGestureProgress', .4);
      expect(
        tester.getRect(find.byKey(const ValueKey('current-page'))),
        isNot(initial),
      );
      expect(navigator.currentState!.canPop(), isTrue);
      await systemGesture('cancelBackGesture');
      expect(
        tester.getRect(find.byKey(const ValueKey('current-page'))),
        initial,
      );
      expect(find.text('Current'), findsOneWidget);
      await systemGesture('startBackGesture', 0);
      await systemGesture('updateBackGestureProgress', .6);
      await systemGesture('commitBackGesture');
      expect(find.text('Current'), findsNothing);
      expect(find.text('Root'), findsOneWidget);
    },
  );
}
