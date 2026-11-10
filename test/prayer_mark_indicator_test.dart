import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/models/prayer_log_status.dart';
import 'package:prayertime/theme/app_colors.dart';
import 'package:prayertime/widgets/prayer_mark_indicator.dart';

void main() {
  for (final dark in [false, true]) {
    for (final status in [null, PrayerLogStatus.onTime, PrayerLogStatus.qada]) {
      testWidgets(
        'swipe check matches widget dimensions and palette: dark=$dark, status=$status',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AnimatedAppPalette(
                dark: dark,
                child: Center(child: PrayerMarkIndicator(status: status)),
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
          expect(tester.widget<Icon>(find.byType(Icon)).size, 24);
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
            expect(xml, contains('android:startColor="#33$hex"'));
            expect(xml, contains('android:endColor="#0D$hex"'));
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
