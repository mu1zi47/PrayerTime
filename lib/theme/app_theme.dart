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
      // Android owns back gestures; ordinary drags never pop a route.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
            fallbackColor: palette.bg,
          ),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(
            backgroundColor: palette.bg,
          ),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(
            backgroundColor: palette.bg,
          ),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(
            backgroundColor: palette.bg,
          ),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(
            backgroundColor: palette.bg,
          ),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(
            backgroundColor: palette.bg,
          ),
        },
      ),
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
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: palette.text.withValues(alpha: .08)),
          gradient: LinearGradient(
            colors: [
              palette.surface.withValues(alpha: .78),
              palette.surface.withValues(alpha: .48),
            ],
          ),
        ),
        textStyle: AppTextStyles.body(fontSize: 14, color: palette.text),
        showDuration: const Duration(seconds: 5),
        exitDuration: const Duration(milliseconds: 140),
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: palette.accent.withValues(alpha: .12),
      highlightColor: palette.accent.withValues(alpha: .06),
    );
  }
}
