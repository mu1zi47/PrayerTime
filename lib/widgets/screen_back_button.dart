import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A round back button matching the design's circular icon-button style
/// (e.g. the Home screen's calendar button), used to head pushed screens
/// that aren't part of the design's static frames.
class ScreenBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const ScreenBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.text),
      ),
    );
  }
}
