import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/theme/app_colors.dart';
import 'package:prayertime/theme/app_theme.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      '${dark ? "dark" : "light"} screen paints an opaque themed background from the first frame',
      (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AnimatedAppPalette(
              dark: dark,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: const SizedBox(
                    width: 200,
                    height: 200,
                    child: AmbientBackground(),
                  ),
                ),
              ),
            ),
          ),
        );
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final picture = await boundary.toImage(pixelRatio: 1);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          picture.dispose();
          return bytes!;
        });
        for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
          expect(
            bytes.getUint8(i + 3),
            255,
            reason: 'the glow must never expose the previous route',
          );
        }
        final center = (100 * 200 + 100) * 4;
        if (dark) {
          expect(bytes.getUint8(center + 2), greaterThan(40));
        } else {
          final pixel = Color.fromARGB(
            255,
            bytes.getUint8(center),
            bytes.getUint8(center + 1),
            bytes.getUint8(center + 2),
          );
          expect(pixel.computeLuminance(), greaterThan(.7));
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
