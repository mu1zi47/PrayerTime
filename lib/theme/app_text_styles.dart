import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading({double fontSize = 20, Color? color}) {
    // Unbounded (the original heading font) is missing Қ/Ғ/Ҳ — used in the
    // Uzbek Cyrillic script — so those letters fell back to the system font
    // mid-word. Exo 2 covers the full Cyrillic range these need.
    return GoogleFonts.exo2(
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: FontWeight.w800,
      height: 1.12,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: fontWeight,
    );
  }
}
