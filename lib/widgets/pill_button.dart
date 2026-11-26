import '../theme/app_design_system.dart';
import 'app_tap.dart';
import 'ambient_surface.dart';
import 'package:flutter/material.dart';

/// Shared glass action button, using the same surface and corners as panels.
class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return Semantics(
      button: true,
      enabled: onTap != null && !loading,
      child: AppTap(
        feedbackOnChild: false,
        onTap: loading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: onTap == null && !loading ? AppOpacity.disabled : 1,
          child: GlassPanel(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: AppPressContent(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loading) ...[
                        SizedBox.square(
                          dimension: AppIconSize.small,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSpacing.micro,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ] else if (icon != null) ...[
                        Icon(
                          icon,
                          size: AppIconSize.medium,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                            fontSize: AppFontSize.body,
                            fontWeight: AppFontWeight.medium,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
