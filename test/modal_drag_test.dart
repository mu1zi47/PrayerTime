import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/widgets/app_modal_sheet.dart';

const bodyKey = ValueKey('drag-modal-body');

Future<void> openSheet(
  WidgetTester tester,
  ScrollController controller, {
  int count = 30,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            child: const Text('open'),
            onPressed: () => showAppModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => SizedBox(
                key: bodyKey,
                height: 480,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 40,
                      child: Center(child: Text('Handle')),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemExtent: 60,
                        itemCount: count,
                        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
                      ),
                    ),
                    const SizedBox(
                      height: 48,
                      child: Center(child: Text('Done')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<TestGesture> beginPull(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getTopLeft(find.byType(ListView)) + const Offset(100, 30),
  );
  // Resolve the drag recognizer's normal touch-slop threshold first.
  await gesture.moveBy(const Offset(0, 24));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('top overscroll follows the finger exactly and can be reversed', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await openSheet(tester, controller);
    final initial = tester.getRect(find.byKey(bodyKey));
    final gesture = await beginPull(tester);
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    final first = tester.getRect(find.byKey(bodyKey));
    expect(first.top, greaterThan(initial.top));
    expect(find.byKey(bodyKey), findsOneWidget);
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(bodyKey)).top - first.top,
      closeTo(60, .1),
    );
    await gesture.moveBy(const Offset(0, -160));
    await tester.pump();
    expect(tester.getRect(find.byKey(bodyKey)).top, closeTo(initial.top, .1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(bodyKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final count in [1, 30]) {
    testWidgets('pull from top closes only on release with $count items', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await openSheet(tester, controller, count: count);
      final gesture = await beginPull(tester);
      await gesture.moveBy(const Offset(0, 270));
      await tester.pump();
      expect(find.byKey(bodyKey), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(bodyKey), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolling above the top is required before moving the sheet', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await openSheet(tester, controller);
    controller.jumpTo(400);
    await tester.pumpAndSettle();
    final initial = tester.getRect(find.byKey(bodyKey));
    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(bodyKey)), initial);
    expect(controller.offset, lessThan(400));
    expect(controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cancelled pull restores the sheet without dismissing', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await openSheet(tester, controller);
    final initial = tester.getRect(find.byKey(bodyKey));
    final gesture = await beginPull(tester);
    await gesture.moveBy(const Offset(0, 220));
    await tester.pump();
    expect(tester.getRect(find.byKey(bodyKey)).top, greaterThan(initial.top));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(bodyKey)), initial);
    expect(tester.takeException(), isNull);
  });
}
