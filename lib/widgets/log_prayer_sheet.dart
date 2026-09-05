import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bottom sheet for marking a single prayer as prayed on time or late —
/// opened from the small badge next to a prayer's time on the home screen
/// (see PrayerRow.onTapLog).
Future<void> showLogPrayerSheet(
  BuildContext context, {
  required String prayerName,
  required PrayerLogStatus? current,
  required void Function(PrayerLogStatus?) onPick,
}) {
  final t = AppLocalizations.of(context)!;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _LogPrayerSheet(
      title: t.logSheetTitle(prayerName),
      subtitle: t.logSheetSubtitle,
      current: current,
      onPick: (status) {
        Navigator.of(sheetContext).pop();
        onPick(status);
      },
    ),
  );
}

class _LogPrayerSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final PrayerLogStatus? current;
  final void Function(PrayerLogStatus?) onPick;

  const _LogPrayerSheet({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              fontSize: 13,
              color: AppColors.text,
            ).copyWith(color: AppColors.text.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 20),
          _LogOption(
            icon: Icons.check_circle_rounded,
            label: t.logSheetOnTime,
            color: AppColors.accent2,
            selected: current == PrayerLogStatus.onTime,
            onTap: () => onPick(PrayerLogStatus.onTime),
          ),
          const SizedBox(height: 10),
          _LogOption(
            icon: Icons.history_toggle_off_rounded,
            label: t.logSheetLate,
            color: AppColors.accent,
            selected: current == PrayerLogStatus.qada,
            onTap: () => onPick(PrayerLogStatus.qada),
          ),
          if (current != null) ...[
            const SizedBox(height: 10),
            _LogOption(
              icon: Icons.close_rounded,
              label: t.logSheetClear,
              color: AppColors.text.withValues(alpha: 0.7),
              selected: false,
              onTap: () => onPick(null),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
