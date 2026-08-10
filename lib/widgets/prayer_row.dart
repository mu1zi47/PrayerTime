import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'prayer_icon.dart';

class PrayerRow extends StatelessWidget {
  final PrayerKind kind;
  final String time;
  final bool active;
  final bool current;

  const PrayerRow({
    super.key,
    required this.kind,
    required this.time,
    this.active = false,
    this.current = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final fg = active ? AppColors.bg : AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: current ? Border.all(color: AppColors.accent, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
            child: Icon(iconForPrayer(kind), size: 19, color: AppColors.accent700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nameForPrayer(t, kind),
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading(fontSize: 15, color: fg),
                ),
                const SizedBox(height: 1),
                Text(
                  arabicForPrayer(kind),
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.body(fontSize: 11, color: fg).copyWith(
                    color: fg.withValues(alpha: active ? 0.85 : 0.65),
                  ),
                ),
              ],
            ),
          ),
          Text(time, style: AppTextStyles.heading(fontSize: 17, color: fg)),
        ],
      ),
    );
  }
}
