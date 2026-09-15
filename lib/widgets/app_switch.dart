import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // On, it takes the same two gold tones as the selected tab and the icon
    // badges (accent100/accent700): the track the deep one, the knob the
    // light one. The ramps run in opposite directions in the two themes
    // (see AppPalette), hence the swap. Off stays a plain grey track.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final deep = dark ? AppColors.accent100 : AppColors.accent700;
    final soft = dark ? AppColors.accent700 : AppColors.accent100;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? deep : AppColors.neutral400,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeOut,
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
    );
  }
}
