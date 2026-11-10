import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/widgets/app_tap.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

void main() {
  Widget button(VoidCallback? onTap, {bool reduceMotion = false}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Center(
            child: AppTap(
              onTap: onTap,
              child: const SizedBox(width: 100, height: 48),
            ),
          ),
        ),
      );

  testWidgets('press stays inside bounds and release invokes action once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(button(() => taps++));
    final bounds = tester.getRect(find.byType(AppTap));
    final gesture = await tester.startGesture(bounds.center);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .97);
    expect(tester.getRect(find.byType(AppTap)), bounds);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('scrolling and cancellation release the pressed state', (
    tester,
  ) async {
    await tester.pumpWidget(button(() {}));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppTap)),
    );
    await tester.pumpAndSettle();
    await gesture.moveBy(const Offset(0, 30));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'press scales content while selected fill and divider remain stationary',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 240,
              child: AppTap(
                feedbackOnChild: false,
                onTap: () {},
                child: PanelRow(
                  selected: true,
                  showDivider: true,
                  child: const AppPressContent(
                    child: Row(
                      children: [
                        Icon(Icons.check),
                        Text('Selected', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final fill = find
          .descendant(
            of: find.byType(PanelRow),
            matching: find.byType(Container),
          )
          .first;
      final line = find.byType(Divider);
      final icon = find.byType(Icon);
      final fillBounds = tester.getRect(fill);
      final lineBounds = tester.getRect(line);
      final iconWidth = tester.getSize(icon).width;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppTap)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .97,
      );
      expect(tester.getRect(fill), fillBounds);
      expect(tester.getRect(line), lineBounds);
      expect(tester.getRect(icon).width, closeTo(iconWidth * .97, .01));
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('disabled controls stay still and reduced motion is respected', (
    tester,
  ) async {
    await tester.pumpWidget(button(null));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppTap)),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
    await tester.pumpWidget(button(() {}, reduceMotion: true));
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
  });
}
