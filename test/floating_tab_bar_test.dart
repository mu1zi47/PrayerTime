import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/widgets/floating_tab_bar.dart';

void main() {
  testWidgets('hold drags only the fill while preserving the original layout', (
    tester,
  ) async {
    var selected = 0;
    var haptics = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: FloatingTabBar(
              index: selected,
              onSelect: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ),
    );
    final capsule = find.byKey(const ValueKey('tab-drag-capsule'));
    final home = find.byIcon(Icons.home_rounded);
    final settings = find.byIcon(Icons.tune_rounded);
    final start = tester.getCenter(home);
    final end = tester.getCenter(settings);
    final label = tester.getTopLeft(find.text('Prayer'));
    final drag = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 300));
    expect(capsule, findsNothing);
    expect(haptics, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(capsule, findsOneWidget);
    expect(haptics, 2);
    await drag.moveTo(end);
    await tester.pump();
    expect(tester.getCenter(home), start);
    expect(tester.getCenter(settings), end);
    expect(tester.getTopLeft(find.text('Prayer')), label);
    expect(
      tester.widget<DecoratedBox>(capsule).decoration,
      isA<BoxDecoration>().having(
        (d) => d.gradient,
        'selection fill',
        isNotNull,
      ),
    );
    await drag.up();
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(capsule, findsNothing);

    final back = await tester.startGesture(tester.getCenter(settings));
    await tester.pump(const Duration(milliseconds: 600));
    await back.moveTo(tester.getCenter(home));
    await back.up();
    await tester.pumpAndSettle();
    expect(selected, 0);

    final beforeHold = haptics;
    final inactive = await tester.startGesture(tester.getCenter(settings));
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected, 0);
    expect(haptics, beforeHold + 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected, 2);
    expect(haptics, beforeHold + 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester.getRect(capsule).contains(tester.getCenter(settings)),
      isTrue,
    );
    await inactive.moveTo(tester.getCenter(home));
    await inactive.up();
    await tester.pumpAndSettle();
    expect(selected, 0);

    final cancel = await tester.startGesture(tester.getCenter(home));
    await tester.pump(const Duration(milliseconds: 600));
    await cancel.moveTo(tester.getCenter(settings));
    await cancel.cancel();
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(capsule, findsNothing);
  });
}
