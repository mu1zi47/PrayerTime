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
      Color badgeColor() {
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(IconBadge),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, isNull);
        expect(decoration.border, isNotNull);
        return (decoration.gradient! as LinearGradient).colors.first;
      }

      expect(
        badgeColor(),
        AppColors.lightPalette.surface.withValues(alpha: .38),
      );
      dark.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 175));
      expect(
        badgeColor(),
        isNot(AppColors.lightPalette.surface.withValues(alpha: .38)),
      );
      expect(
        badgeColor(),
        isNot(AppColors.darkPalette.surface.withValues(alpha: .38)),
      );
      await tester.pumpAndSettle();
      expect(
        badgeColor(),
        AppColors.darkPalette.surface.withValues(alpha: .38),
      );
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.darkPalette.accent700,
      );

      dark.value = false;
      await tester.pumpAndSettle();
      expect(
        badgeColor(),
        AppColors.lightPalette.surface.withValues(alpha: .38),
      );
      expect(
        tester.widget<Icon>(find.byType(Icon)).color,
        AppColors.lightPalette.accent700,
      );
    },
  );
}
