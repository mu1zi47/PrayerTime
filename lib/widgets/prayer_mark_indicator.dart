import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/prayer_log_status.dart';
import '../theme/app_colors.dart';

/// Same 48dp surface, 24dp check and 12dp corners as the Android widget.
/// Both logged statuses are checked, as in the widget; the prayer log keeps
/// the on-time/late distinction and exposes it in the accessibility label.
class PrayerMarkIndicator extends StatelessWidget {
  final PrayerLogStatus? status;
  const PrayerMarkIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final ink = AppColors.accent700;
    final marked = status != null;
    final t = AppLocalizations.of(context)!;
    return Semantics(
      label: switch (status) {
        PrayerLogStatus.onTime => t.logSheetOnTime,
        PrayerLogStatus.qada => t.logSheetLate,
        null => t.logSheetSubtitle,
      },
      child: Container(
        key: ValueKey('prayer-swipe-preview-${status?.name ?? 'unread'}'),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ink.withAlpha(marked ? 0x66 : 0x40)),
          gradient: marked
              ? LinearGradient(
                  colors: [ink.withAlpha(0x33), ink.withAlpha(0x0d)],
                )
              : null,
        ),
        child: Icon(Icons.check, size: 24, color: ink),
      ),
    );
  }
}
