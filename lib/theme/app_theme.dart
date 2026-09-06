import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Built once, not per access: MaterialApp reads both on every rebuild, and
  // ColorScheme.fromSeed below derives a whole palette each time it runs.
  static final ThemeData light = _build(
    AppColors.lightPalette,
    Brightness.light,
  );

  static final ThemeData dark = _build(AppColors.darkPalette, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      fontFamily: AppTextStyles.body().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        surface: palette.bg,
      ),
      textTheme: TextTheme(
        bodyMedium: AppTextStyles.body(color: palette.text),
        bodyLarge: AppTextStyles.body(color: palette.text),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
