import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/widgets/app_search_field.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

void main() {
  testWidgets('search and clear icons have equal visible edge spacing', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Ташкент');
    addTearDown(controller.dispose);
    var changed = 'Ташкент';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            controller: controller,
            onChanged: (v) => changed = v,
            hint: 'Поиск',
          ),
        ),
      ),
    );
    final bounds = tester.getRect(find.byType(GlassPanel));
    final search = tester.getRect(find.byIcon(Icons.search_rounded));
    final clear = tester.getRect(find.byIcon(Icons.close_rounded));
    expect(search.left - bounds.left, closeTo(bounds.right - clear.right, .1));
    expect(search.center.dy, clear.center.dy);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(changed, isEmpty);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
