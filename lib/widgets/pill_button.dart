import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The app's main button: soft gold, deep gold text (see IconBadge), faded
/// while there's nothing it can do.
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const PillButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accent100,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: AppColors.accent700),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
