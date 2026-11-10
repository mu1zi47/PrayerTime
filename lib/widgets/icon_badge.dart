import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared translucent icon tile for prayer rows, settings and pickers.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  /// Overrides for a badge sitting on a surface that is itself soft gold
  /// (a highlighted row), where the default would vanish into it.
  final Color? background;
  final Color? foreground;

  const IconBadge(
    this.icon, {
    super.key,
    this.size = 34,
    this.iconSize = 17,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: iconBadgeDecoration(size: size, tint: background),
      child: Icon(
        icon,
        size: iconSize,
        color: foreground ?? AppColors.accent700,
      ),
    );
  }
}

/// A translucent icon surface using the same navy/white glass as panels.
BoxDecoration iconBadgeDecoration({double size = 34, Color? tint}) =>
    BoxDecoration(
      borderRadius: BorderRadius.circular(size * .32),
      border: Border.all(color: AppColors.text.withValues(alpha: .08)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (tint ?? AppColors.surface).withValues(
            alpha: tint == null ? .38 : .12,
          ),
          AppColors.surface.withValues(alpha: .12),
        ],
      ),
    );

/// Number counterpart to IconBadge, with a compact, evenly led line box.
class NumberBadge extends StatelessWidget {
  final int number;
  final double size;
  final double fontSize;
  const NumberBadge(
    this.number, {
    super.key,
    this.size = 40,
    this.fontSize = 13,
  });
  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: iconBadgeDecoration(size: size),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style:
            AppTextStyles.body(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.accent700,
            ).copyWith(
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
            ),
      ),
    );
  }
}
