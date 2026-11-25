import '../theme/app_design_system.dart';
import 'app_tap.dart';
import 'ambient_surface.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'icon_badge.dart';

/// Sits above the per-prayer notification modes while the phone isn't
/// letting this app's notifications through (see
/// AppState.notificationsAllowed): says why the modes read as off and won't
/// change, and offers the way to fix it. The same card as the Now Bar's
/// developer-switch steps (NowBarDeveloperSwitchCard), so the app's "fix
/// this on the phone" notices all look alike.
class NotificationsBlockedNotice extends StatelessWidget {
  final VoidCallback onAllow;

  const NotificationsBlockedNotice({super.key, required this.onAllow});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final t = AppLocalizations.of(context)!;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                Icons.notifications_off_rounded,
                size: AppIconSize.display,
                iconSize: AppIconSize.small,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  t.notifBlockedTitle,
                  style: AppTextStyles.heading(fontSize: AppFontSize.body),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.notifBlockedBody,
            style: AppTextStyles.body(
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w400,
              color: AppColors.text.withValues(alpha: 0.8),
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTap(
            feedbackOnChild: false,
            onTap: onAllow,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.text.withValues(alpha: AppOpacity.border),
                ),
                gradient: AppColors.selectionGradient,
                borderRadius: BorderRadius.circular(AppRadius.inner),
              ),
              child: AppPressContent(
                child: Text(
                  t.notifBlockedAllow,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
