import 'package:flutter/material.dart';

import '../models/prayer_log_status.dart';
import 'app_colors.dart';

/// Semantic prayer marks share the neutral application palette.
class StatusColors {
  StatusColors._();

  static Color get onTime => AppColors.accent;

  static Color get onOnTime => AppColors.bg;

  static Color of(PrayerLogStatus status) => switch (status) {
    PrayerLogStatus.onTime => onTime,
  };

  static Color onFillOf(PrayerLogStatus status) => switch (status) {
    PrayerLogStatus.onTime => onOnTime,
  };
}
