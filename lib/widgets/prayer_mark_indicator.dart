import '../theme/app_design_system.dart';
import 'app_tap.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';

/// Shared binary prayer button, matching the Android widget.
class PrayerMarkIndicator extends StatelessWidget {
  final PrayerLogStatus? status;
  final VoidCallback? onTap;
  const PrayerMarkIndicator({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final ink = AppColors.accent700;
    final marked = status != null;
    final t = AppLocalizations.of(context)!;
    return Semantics(
      label: marked ? t.widgetMarkedLabel : t.calendarNotMarked,
      checked: marked,
      button: true,
      enabled: onTap != null,
      child: AppTap(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSize.touchTarget,
          child: Center(
            child: Container(
              key: ValueKey('prayer-swipe-preview-${status?.name ?? 'unread'}'),
              width: AppSize.badge,
              height: AppSize.badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: ink.withAlpha(marked ? 0x66 : 0x40)),
                gradient: marked
                    ? LinearGradient(
                        colors: [ink.withAlpha(0x33), ink.withAlpha(0x0d)],
                      )
                    : null,
              ),
              child: Icon(
                Icons.check,
                size: AppIconSize.small,
                color: onTap == null
                    ? ink.withValues(alpha: AppOpacity.disabled)
                    : ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
