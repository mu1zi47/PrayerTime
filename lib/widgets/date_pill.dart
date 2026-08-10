import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DatePill extends StatelessWidget {
  final String weekday;
  final String dayNumber;
  final bool selected;
  final bool isToday;
  final VoidCallback? onTap;

  const DatePill({
    super.key,
    required this.weekday,
    required this.dayNumber,
    this.selected = false,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.bg : AppColors.text;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: isToday && !selected ? Border.all(color: AppColors.accent, width: 1.8) : null,
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: AppTextStyles.body(fontSize: 11, color: fg).copyWith(
                color: fg.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(dayNumber, style: AppTextStyles.heading(fontSize: 16, color: fg)),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? fg.withValues(alpha: selected ? 0.9 : 0.8) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
