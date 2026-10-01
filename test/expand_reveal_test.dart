import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayertime/widgets/expand_reveal.dart';

void main() {
  Widget host(bool visible) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExpandReveal(
              visible: visible,
              child: const SizedBox(height: 80, child: Text('schedule')),
            ),
          ],
        ),
      ),
    ),
  );

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(ExpandReveal)).height;

  testWidgets('opens gradually, then folds away again', (tester) async {
    await tester.pumpWidget(host(false));
    expect(height(tester), 0);

    await tester.pumpWidget(host(true));
    await tester.pump(const Duration(milliseconds: 120));
    // Partway: neither closed nor fully open — the sheet grows with it.
    expect(height(tester), inExclusiveRange(0, 80));

    await tester.pumpAndSettle();
    expect(height(tester), 80);

    await tester.pumpWidget(host(false));
    await tester.pumpAndSettle();
    expect(height(tester), 0);
    expect(find.text('schedule'), findsNothing);
  });
}
