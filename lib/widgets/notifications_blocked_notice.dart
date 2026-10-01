import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                Icons.notifications_off_rounded,
                size: 30,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.notifBlockedTitle,
                  style: AppTextStyles.heading(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.notifBlockedBody,
            style: AppTextStyles.body(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColors.text.withValues(alpha: 0.8),
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onAllow,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                t.notifBlockedAllow,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
