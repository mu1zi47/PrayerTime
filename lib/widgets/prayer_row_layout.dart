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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < AppSize.largeTextRowWidth &&
            scaler.scale(AppFontSize.body) > AppFontSize.body * 1.4;
        final timeHeight = stacked
            ? scaler.scale(AppFontSize.bodyLarge) * 1.25 + AppSpacing.xxs
            : 0.0;
        return SizedBox(
          height: math.max(
            AppSize.prayerRow,
            textHeight + timeHeight + AppSpacing.xxs * 2,
          ),
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
                Expanded(
                  child: stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            label,
                            if (time != null) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: time,
                              ),
                            ],
                          ],
                        )
                      : label,
                ),
                if (!stacked && time != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  time!,
                ],
                const SizedBox(width: AppSpacing.xs),
                SizedBox.square(dimension: AppSize.touchTarget, child: mark),
              ],
            ),
          ),
        );
      },
    );
  }
}
