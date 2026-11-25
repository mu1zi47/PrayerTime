import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

enum PrayerRowVariant { plain, contained }

/// Shared geometry for every prayer row, including informational rows.
/// Empty trailing slots preserve both the row height and time alignment.
class PrayerRowLayout extends StatelessWidget {
  const PrayerRowLayout({
    super.key,
    required this.leading,
    required this.label,
    this.time,
    this.mark,
    this.variant = PrayerRowVariant.contained,
  });
  final Widget leading;
  final Widget label;
  final Widget? time;
  final Widget? mark;
  final PrayerRowVariant variant;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final title = AppTextStyles.prayerName();
    final subtitle = AppTextStyles.prayerSubtitle();
    final textHeight =
        (scaler.scale(title.fontSize!) * title.height!).ceilToDouble() +
        (scaler.scale(subtitle.fontSize!) * subtitle.height!).ceilToDouble();
    return SizedBox(
      height: math.max(AppSize.prayerRow, textHeight + AppSpacing.xxs * 2),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: variant == PrayerRowVariant.contained
              ? AppSpacing.sm
              : AppSpacing.none,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: AppSize.touchTarget,
              child: Center(child: leading),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: label),
            if (time != null) ...[const SizedBox(width: AppSpacing.xs), time!],
            const SizedBox(width: AppSpacing.xs),
            SizedBox.square(dimension: AppSize.touchTarget, child: mark),
          ],
        ),
      ),
    );
  }
}
