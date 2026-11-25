import 'app_tokens.dart';
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
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: palette.accent,
            brightness: brightness,
            surface: palette.bg,
          ).copyWith(
            primary: palette.accent,
            onPrimary: palette.bg,
            secondary: palette.accent2,
            onSecondary: palette.bg,
            tertiary: palette.text,
            onTertiary: palette.bg,
            primaryContainer: palette.controlFill,
            onPrimaryContainer: palette.onControlFill,
            secondaryContainer: palette.surface,
            onSecondaryContainer: palette.text,
            surfaceTint: AppColors.transparent,
            onSurface: palette.text,
            onSurfaceVariant: palette.text.withValues(
              alpha: AppOpacity.secondary,
            ),
            outline: palette.divider,
            error: AppColors.destructive,
          ),
      textTheme: TextTheme(
        bodySmall: AppTextStyles.body(
          fontSize: AppFontSize.small,
          color: palette.text,
        ),
        bodyMedium: AppTextStyles.body(
          fontSize: AppFontSize.body,
          color: palette.text,
        ),
        bodyLarge: AppTextStyles.body(
          fontSize: AppFontSize.bodyLarge,
          color: palette.text,
        ),
        labelSmall: AppTextStyles.body(
          fontSize: AppFontSize.caption,
          color: palette.text,
        ),
        labelMedium: AppTextStyles.body(
          fontSize: AppFontSize.small,
          color: palette.text,
        ),
        labelLarge: AppTextStyles.body(
          fontSize: AppFontSize.body,
          color: palette.text,
        ),
        titleSmall: AppTextStyles.heading(
          fontSize: AppFontSize.bodyLarge,
          color: palette.text,
        ),
        titleMedium: AppTextStyles.heading(
          fontSize: AppFontSize.title,
          color: palette.text,
        ),
        titleLarge: AppTextStyles.heading(
          fontSize: AppFontSize.heading,
          color: palette.text,
        ),
        headlineSmall: AppTextStyles.heading(
          fontSize: AppFontSize.heading,
          color: palette.text,
        ),
        headlineMedium: AppTextStyles.heading(
          fontSize: AppFontSize.display,
          color: palette.text,
        ),
        headlineLarge: AppTextStyles.heading(
          fontSize: AppFontSize.timer,
          color: palette.text,
        ),
        displaySmall: AppTextStyles.heading(
          fontSize: AppFontSize.hero,
          color: palette.text,
        ),
        displayMedium: AppTextStyles.heading(
          fontSize: AppFontSize.hero,
          color: palette.text,
        ),
        displayLarge: AppTextStyles.heading(
          fontSize: AppFontSize.counter,
          color: palette.text,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: palette.text.withValues(alpha: AppOpacity.border),
          ),
          gradient: LinearGradient(
            colors: [
              palette.surface.withValues(alpha: AppOpacity.strong),
              palette.surface.withValues(alpha: .48),
            ],
          ),
        ),
        textStyle: AppTextStyles.body(
          fontSize: AppFontSize.body,
          color: palette.text,
        ),
        showDuration: const Duration(seconds: 5),
        exitDuration: const Duration(milliseconds: 140),
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: palette.accent.withValues(alpha: AppOpacity.tint),
      highlightColor: palette.accent.withValues(alpha: .06),
    );
  }
}
