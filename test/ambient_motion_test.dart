import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

void expectPosition(Alignment expected) {
  expect(ambientPosition.value.x, closeTo(expected.x, .000001));
  expect(ambientPosition.value.y, closeTo(expected.y, .000001));
}

void main() {
  setUp(() => moveAmbientLight(AmbientNavigationObserver.positions[0]));

  testWidgets(
    'glow follows a held swipe and reverses without a delayed tween',
    (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);
      final positions = AmbientNavigationObserver.positions.take(3).toList();
      await tester.pumpWidget(
        MaterialApp(
          home: AmbientScaffold(
            body: AmbientPageMotion(
              anchorToCurrent: false,
              positions: positions,
              child: PageView(
                controller: controller,
                children: const [SizedBox(), SizedBox(), SizedBox()],
              ),
            ),
          ),
        ),
      );
      final drag = await tester.startGesture(const Offset(650, 250));
      await drag.moveBy(const Offset(-180, 0));
      await tester.pump();
      final page = controller.page!;
      expect(page, inExclusiveRange(0, .5));
      expect(
        ambientPosition.value,
        Alignment.lerp(positions[0], positions[1], page),
      );
      final held = ambientPosition.value;
      await tester.pump(const Duration(milliseconds: 600));
      expect(ambientPosition.value, held);
      await drag.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(controller.page!, lessThan(page));
      expect(
        ambientPosition.value,
        Alignment.lerp(positions[0], positions[1], controller.page!),
      );
      await drag.cancel();
      await tester.pumpAndSettle();
      expect(controller.page, 0);
      expect(ambientPosition.value, positions[0]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('nested vertical scrolling does not move the pager glow', (
    tester,
  ) async {
    final start = ambientPosition.value;
    await tester.pumpWidget(
      MaterialApp(
        home: AmbientScaffold(
          body: AmbientPageMotion(
            positions: AmbientNavigationObserver.positions,
            child: PageView(
              children: [
                ListView(children: const [SizedBox(height: 2000)]),
                const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(ambientPosition.value, start);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('predictive back follows progress, cancellation and commit', (
    tester,
  ) async {
    final observer = AmbientNavigationObserver();
    addTearDown(observer.dispose);
    final navigator = GlobalKey<NavigatorState>();
    final start = ambientPosition.value;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        home: const AmbientScaffold(body: SizedBox()),
      ),
    );
    final route = MaterialPageRoute<void>(
      builder: (_) => const AmbientScaffold(body: SizedBox()),
    );
    navigator.currentState!.push(route);
    await tester.pumpAndSettle();
    final opened = ambientPosition.value;
    expect(opened, isNot(start));

    route.handleStartBackGesture(progress: .95);
    expectPosition(Alignment.lerp(opened, start, .05)!);
    route.handleUpdateBackGestureProgress(progress: .7);
    await tester.pump();
    expectPosition(Alignment.lerp(opened, start, .3)!);
    final held = ambientPosition.value;
    await tester.pump(const Duration(milliseconds: 500));
    expect(ambientPosition.value, held);
    route.handleUpdateBackGestureProgress(progress: .9);
    await tester.pump();
    expectPosition(Alignment.lerp(opened, start, .1)!);
    route.handleCancelBackGesture();
    await tester.pumpAndSettle();
    expect(ambientPosition.value, opened);
    expect(route.isCurrent, isTrue);

    route.handleStartBackGesture(progress: 1);
    route.handleUpdateBackGestureProgress(progress: .6);
    await tester.pump();
    final preview = ambientPosition.value;
    route.handleCommitBackGesture();
    await tester.pump();
    expect(ambientPosition.value, preview);
    await tester.pumpAndSettle();
    expect(ambientPosition.value, start);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
