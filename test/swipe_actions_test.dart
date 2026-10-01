import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayertime/widgets/swipe_actions.dart';

void main() {
  var deleted = 0;
  var switchedOff = 0;

  Widget tile() => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: SwipeActionTile(
            actions: [
              SwipeAction(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: Colors.red,
                foreground: Colors.white,
                onPressed: () => deleted++,
              ),
              SwipeAction(
                icon: Icons.alarm_off_rounded,
                label: 'Off for today',
                color: Colors.amber,
                foreground: Colors.black,
                onPressed: () => switchedOff++,
              ),
            ],
            child: const SizedBox(height: 60, child: Text('reminder')),
          ),
        ),
      ),
    ),
  );

  setUp(() {
    deleted = 0;
    switchedOff = 0;
  });

  testWidgets('a full swipe runs the last action and closes again', (
    tester,
  ) async {
    await tester.pumpWidget(tile());
    final rest = tester.getTopLeft(find.text('reminder')).dx;
    await tester.drag(find.text('reminder'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(switchedOff, 1);
    expect(deleted, 0);
    expect(tester.getTopLeft(find.text('reminder')).dx, rest);
  });

  testWidgets('a shorter swipe leaves the actions open to tap', (tester) async {
    await tester.pumpWidget(tile());
    final rest = tester.getTopLeft(find.text('reminder')).dx;
    await tester.drag(find.text('reminder'), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(switchedOff, 0);
    expect(tester.getTopLeft(find.text('reminder')).dx, lessThan(rest));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
    expect(tester.getTopLeft(find.text('reminder')).dx, rest);
  });

  testWidgets('a nudge springs back without doing anything', (tester) async {
    await tester.pumpWidget(tile());
    final rest = tester.getTopLeft(find.text('reminder')).dx;
    await tester.drag(find.text('reminder'), const Offset(-50, 0));
    await tester.pumpAndSettle();

    expect(deleted + switchedOff, 0);
    expect(tester.getTopLeft(find.text('reminder')).dx, rest);
  });
}
