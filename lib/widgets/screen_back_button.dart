import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
