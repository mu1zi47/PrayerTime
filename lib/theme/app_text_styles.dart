import 'app_tokens.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One bundled Exo 2 family with semantic weights for all text roles.
///
/// A variable font needs the weight on *two* channels: [FontWeight] is what
/// Flutter lays out and matches against, while [FontVariation] on the `wght`
/// axis is what the font itself renders. Without the variation the file
/// draws at its default weight (Regular) no matter what FontWeight says.
class AppTextStyles {
  AppTextStyles._();

  static const _headingFamily = 'Exo2';
  static const _bodyFamily = 'Exo2';

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
  static TextStyle heading({
    double fontSize = AppFontSize.heading,
    Color? color,
    FontWeight fontWeight = AppFontWeight.heading,
  }) {
    return TextStyle(
      fontFamily: _headingFamily,
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: fontWeight,
      fontVariations:
          _weightAxis[fontWeight.value] ??
          [FontVariation('wght', fontWeight.value.toDouble())],
      height: 1.25,
    );
  }

  static TextStyle prayerName({Color? color}) => heading(
    fontSize: AppFontSize.body,
    color: color,
    fontWeight: AppFontWeight.medium,
  );

  // Inline labels use the name's font metrics so their visual centers match.
  static TextStyle prayerInlineLabel({Color? color}) =>
      heading(fontSize: AppFontSize.caption, color: color);

  static TextStyle prayerSubtitle({Color? color}) =>
      body(fontSize: AppFontSize.caption, color: color).copyWith(height: 1.4);

  static TextStyle body({
    double fontSize = AppFontSize.body,
    Color? color,
    FontWeight fontWeight = AppFontWeight.regular,
  }) {
    return TextStyle(
      fontFamily: _bodyFamily,
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: fontWeight,
      fontVariations:
          _weightAxis[fontWeight.value] ??
          [FontVariation('wght', fontWeight.value.toDouble())],
      height: 1.4,
    );
  }
}
