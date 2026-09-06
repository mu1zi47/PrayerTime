import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's two faces, both bundled as variable fonts (see pubspec's
/// `fonts:` section) rather than pulled at runtime by google_fonts — that
/// package fetched them over the network on first launch, so the first
/// frames rendered in a fallback face.
///
/// A variable font needs the weight on *two* channels: [FontWeight] is what
/// Flutter lays out and matches against, while [FontVariation] on the `wght`
/// axis is what the font itself renders. Without the variation the file
/// draws at its default weight (Regular) no matter what FontWeight says.
class AppTextStyles {
  AppTextStyles._();

  static const _headingFamily = 'Exo2';
  static const _bodyFamily = 'Nunito';

  // Pre-built per weight: body() runs for essentially every Text in the
  // app, and each call would otherwise allocate a fresh list and variation.
  static const _weightAxis = <int, List<FontVariation>>{
    400: [FontVariation('wght', 400)],
    600: [FontVariation('wght', 600)],
    700: [FontVariation('wght', 700)],
    800: [FontVariation('wght', 800)],
  };

  /// Exo 2 — chosen over the original heading font because it covers Қ/Ғ/Ҳ,
  /// the Uzbek Cyrillic letters that otherwise fell back to the system font
  /// mid-word.
  static TextStyle heading({double fontSize = 20, Color? color}) {
    return TextStyle(
      fontFamily: _headingFamily,
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: FontWeight.w800,
      fontVariations: const [FontVariation('wght', 800)],
      height: 1.12,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: fontWeight,
      fontVariations:
          _weightAxis[fontWeight.value] ??
          [FontVariation('wght', fontWeight.value.toDouble())],
    );
  }
}
