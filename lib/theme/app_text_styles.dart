import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles for the Organic design system. The design's original
/// Caprasimo/Figtree pairing has no Cyrillic glyphs, so Russian text
/// silently fell back to the default system font — Unbounded (headings)
/// and Nunito (body) keep the same rounded, warm character while fully
/// supporting Cyrillic.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading({double fontSize = 20, Color? color}) {
    return GoogleFonts.unbounded(
      fontSize: fontSize,
      color: color ?? AppColors.text,
      fontWeight: FontWeight.w600,
      height: 1.12,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.nunito(fontSize: fontSize, color: color ?? AppColors.text, fontWeight: fontWeight);
  }
}
