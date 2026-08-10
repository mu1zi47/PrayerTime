import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

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
