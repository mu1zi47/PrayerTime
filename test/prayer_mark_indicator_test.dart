import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiveglow/l10n/app_localizations.dart';
import 'package:fiveglow/models/prayer_log_status.dart';
import 'package:fiveglow/theme/app_colors.dart';
import 'package:fiveglow/widgets/prayer_mark_indicator.dart';

void main() {
  for (final dark in [false, true]) {
    for (final status in [null, PrayerLogStatus.onTime]) {
      testWidgets(
        'swipe check matches widget dimensions and palette: dark=$dark, status=$status',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AnimatedAppPalette(
                dark: dark,
                child: Center(
                  child: PrayerMarkIndicator(status: status, onTap: () {}),
                ),
              ),
            ),
          );
          final surface = tester.widget<Container>(
            find.byKey(
              ValueKey('prayer-swipe-preview-${status?.name ?? 'unread'}'),
            ),
          );
          final decoration = surface.decoration! as BoxDecoration;
          final ink =
              (dark ? AppColors.darkPalette : AppColors.lightPalette).accent700;
          expect(
            tester.getSize(find.byType(PrayerMarkIndicator)),
            const Size(48, 48),
          );
          expect(decoration.borderRadius, BorderRadius.circular(12));
          expect((decoration.border! as Border).top.width, 1);
          expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.check);
          expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
          expect(
            tester.getSize(
              find.byKey(
                ValueKey('prayer-swipe-preview-${status?.name ?? 'unread'}'),
              ),
            ),
            const Size(32, 32),
          );
          expect(tester.widget<Icon>(find.byType(Icon)).color, ink);
          if (status == null) {
            expect(decoration.gradient, isNull);
            expect(
              (decoration.border! as Border).top.color,
              ink.withAlpha(0x40),
            );
          } else {
            final theme = dark ? 'dark' : 'light';
            final xml = File(
              'android/app/src/main/res/drawable/widget_button_marked_$theme.xml',
            ).readAsStringSync();
            final hex = ink
                .toARGB32()
                .toRadixString(16)
                .substring(2)
                .toUpperCase();
            expect(xml, contains('android:radius="12dp"'));
            expect(xml, contains('android:width="1dp"'));
            final resources = File(
              'android/app/src/main/res/values/app_design_tokens.xml',
            ).readAsStringSync();
            final token = 'app_ds_${theme}_accent';
            expect(xml, contains('android:startColor="@color/${token}_33"'));
            expect(xml, contains('android:endColor="@color/${token}_0d"'));
            expect(
              resources,
              contains('<color name="${token}_33">#33$hex</color>'),
            );
            expect(
              resources,
              contains('<color name="${token}_0d">#0D$hex</color>'),
            );
            expect((decoration.gradient! as LinearGradient).colors, [
              ink.withAlpha(0x33),
              ink.withAlpha(0x0d),
            ]);
            expect(
              (decoration.border! as Border).top.color,
              ink.withAlpha(0x66),
            );
          }
        },
      );
    }
  }
}
