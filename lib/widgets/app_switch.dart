import 'app_tap.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    // Semantic colors interpolate across the reversed light/dark ramps.
    final soft = AppColors.onControlFill;
    return AppTap(
      feedbackOnChild: false,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.text.withValues(alpha: .08)),
          color: value ? null : AppColors.neutral400,
          gradient: value ? AppColors.selectionGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeOut,
          child: AppPressContent(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? soft : Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
