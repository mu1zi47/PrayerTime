import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/widgets/screen_back_button.dart';

void main() {
  testWidgets('back button remains circular inside a tall app bar', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            toolbarHeight: 76,
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: ScreenBackButton(onTap: () => taps++),
            ),
          ),
        ),
      ),
    );
    final circle = find.descendant(
      of: find.byType(ScreenBackButton),
      matching: find.byType(ClipOval),
    );
    expect(tester.getSize(circle), const Size(38, 38));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
