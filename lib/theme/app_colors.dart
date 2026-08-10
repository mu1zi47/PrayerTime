import 'package:flutter/material.dart';

class AppPalette {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;

  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;

  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent400;
  final Color accent500;
  final Color accent600;
  final Color accent700;
  final Color accent800;
  final Color accent900;

  final Color accent2_100;
  final Color accent2_200;
  final Color accent2_300;
  final Color accent2_400;
  final Color accent2_500;
  final Color accent2_600;
  final Color accent2_700;
  final Color accent2_800;
  final Color accent2_900;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent500,
    required this.accent600,
    required this.accent700,
    required this.accent800,
    required this.accent900,
    required this.accent2_100,
    required this.accent2_200,
    required this.accent2_300,
    required this.accent2_400,
    required this.accent2_500,
    required this.accent2_600,
    required this.accent2_700,
    required this.accent2_800,
    required this.accent2_900,
  });

  Color get divider => text.withValues(alpha: 0.16);
}

const _light = AppPalette(
  bg: Color(0xFFF5EAD8),
  surface: Color(0xFFEBDDC5),
  text: Color(0xFF201E1D),
  accent: Color(0xFFC67139),
  accent2: Color(0xFF7A8A5E),
  neutral100: Color(0xFFF9F4ED),
  neutral200: Color(0xFFEEE7DB),
  neutral300: Color(0xFFDCD3C4),
  neutral400: Color(0xFFC0B6A5),
  neutral500: Color(0xFFA19786),
  neutral600: Color(0xFF82796A),
  neutral700: Color(0xFF645C50),
  neutral800: Color(0xFF474238),
  neutral900: Color(0xFF2E2B25),
  accent100: Color(0xFFFFF2EB),
  accent200: Color(0xFFFFE1D0),
  accent300: Color(0xFFFFC6A5),
  accent400: Color(0xFFF6A06B),
  accent500: Color(0xFFD67F48),
  accent600: Color(0xFFB2622D),
  accent700: Color(0xFF8C491A),
  accent800: Color(0xFF643312),
  accent900: Color(0xFF402310),
  accent2_100: Color(0xFFF0FAE1),
  accent2_200: Color(0xFFE1EECC),
  accent2_300: Color(0xFFCCDBB2),
  accent2_400: Color(0xFFAEBF92),
  accent2_500: Color(0xFF8FA073),
  accent2_600: Color(0xFF728157),
  accent2_700: Color(0xFF56633F),
  accent2_800: Color(0xFF3D472B),
  accent2_900: Color(0xFF272E1B),
);

// Mirrors `_light`'s internal logic (the NNN scales run from "closest to
// bg" to "closest to text/most saturated") but with the ramp direction
// flipped, since in dark mode the darkest tone is the background and the
// lightest is the readable-on-dark end.
const _dark = AppPalette(
  bg: Color(0xFF17130F),
  surface: Color(0xFF241E17),
  text: Color(0xFFF3E9DA),
  accent: Color(0xFFE08A52),
  accent2: Color(0xFF9AAE7C),
  neutral100: Color(0xFF211C16),
  neutral200: Color(0xFF2C2620),
  neutral300: Color(0xFF3A3229),
  neutral400: Color(0xFF4C4235),
  neutral500: Color(0xFF665A49),
  neutral600: Color(0xFF82725D),
  neutral700: Color(0xFFA08D73),
  neutral800: Color(0xFFC2AF95),
  neutral900: Color(0xFFE4D9C7),
  accent100: Color(0xFF3A2415),
  accent200: Color(0xFF4A2E1B),
  accent300: Color(0xFF5D3A22),
  accent400: Color(0xFF7A4B2A),
  accent500: Color(0xFF9C5F35),
  accent600: Color(0xFFC67139),
  accent700: Color(0xFFE08A52),
  accent800: Color(0xFFF0AC7C),
  accent900: Color(0xFFFBE0CC),
  accent2_100: Color(0xFF1E2416),
  accent2_200: Color(0xFF29321D),
  accent2_300: Color(0xFF384325),
  accent2_400: Color(0xFF4D5A32),
  accent2_500: Color(0xFF647240),
  accent2_600: Color(0xFF7C8F52),
  accent2_700: Color(0xFF9AAE7C),
  accent2_800: Color(0xFFBFCDA6),
  accent2_900: Color(0xFFE3EBD3),
);


class AppColors {
  AppColors._();

  static const AppPalette lightPalette = _light;
  static const AppPalette darkPalette = _dark;

  static bool _isDark = false;

  static void setDark(bool value) => _isDark = value;

  static AppPalette get _active => _isDark ? _dark : _light;

  static Color get bg => _active.bg;
  static Color get surface => _active.surface;
  static Color get text => _active.text;
  static Color get accent => _active.accent;
  static Color get accent2 => _active.accent2;
  static Color get divider => _active.divider;

  static Color get neutral100 => _active.neutral100;
  static Color get neutral200 => _active.neutral200;
  static Color get neutral300 => _active.neutral300;
  static Color get neutral400 => _active.neutral400;
  static Color get neutral500 => _active.neutral500;
  static Color get neutral600 => _active.neutral600;
  static Color get neutral700 => _active.neutral700;
  static Color get neutral800 => _active.neutral800;
  static Color get neutral900 => _active.neutral900;

  static Color get accent100 => _active.accent100;
  static Color get accent200 => _active.accent200;
  static Color get accent300 => _active.accent300;
  static Color get accent400 => _active.accent400;
  static Color get accent500 => _active.accent500;
  static Color get accent600 => _active.accent600;
  static Color get accent700 => _active.accent700;
  static Color get accent800 => _active.accent800;
  static Color get accent900 => _active.accent900;

  static Color get accent2_100 => _active.accent2_100;
  static Color get accent2_200 => _active.accent2_200;
  static Color get accent2_300 => _active.accent2_300;
  static Color get accent2_400 => _active.accent2_400;
  static Color get accent2_500 => _active.accent2_500;
  static Color get accent2_600 => _active.accent2_600;
  static Color get accent2_700 => _active.accent2_700;
  static Color get accent2_800 => _active.accent2_800;
  static Color get accent2_900 => _active.accent2_900;
}

class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 28.0;
}
