import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/theme/app_colors.dart';
import 'package:prayertime/widgets/icon_badge.dart';

void main() {
  testWidgets(
    'const badges recolor during a theme transition without navigation',
    (tester) async {
      final dark = ValueNotifier(false);
      addTearDown(dark.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: dark,
            builder: (context, value, child) =>
                AnimatedAppPalette(dark: value, child: child!),
            child: const IconBadge(Icons.access_time_rounded),
          ),
        ),
      );
      Color badgeColor() =>
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: find.byType(IconBadge),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .color!;

      expect(badgeColor(), AppColors.lightPalette.accent100);
      dark.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(badgeColor(), isNot(AppColors.lightPalette.accent100));
      expect(badgeColor(), isNot(AppColors.darkPalette.accent100));
      await tester.pumpAndSettle();
      expect(badgeColor(), AppColors.darkPalette.accent100);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.darkPalette.accent700,
      );

      dark.value = false;
      await tester.pumpAndSettle();
      expect(badgeColor(), AppColors.lightPalette.accent100);
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.lightPalette.accent700,
      );
    },
  );
}
