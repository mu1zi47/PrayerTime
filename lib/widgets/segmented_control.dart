import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A minimal text-tabs control — plain labels with a short accent underline
/// on the selected one, the same "no fill, no border, just an accent mark"
/// language as HomeScreen's own day strip, rather than a filled sliding
/// capsule.
class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          GestureDetector(
            onTap: () => onSelect(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    fontWeight: i == selectedIndex
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: i == selectedIndex
                        ? AppColors.accent
                        : AppColors.text.withValues(alpha: 0.5),
                  ),
                  child: Text(options[i]),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 3,
                  width: i == selectedIndex ? 22 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
