import 'package:flutter/material.dart';

import '../models/prayer_log_status.dart';
import 'app_colors.dart';

/// The colors a logged prayer is marked with, everywhere in the app: the
/// brighter gold for "on time" — the better outcome stands out more — and
/// the deeper one for "qada" (made up late).
class StatusColors {
  StatusColors._();

  static Color get onTime => AppColors.accent;
  static Color get qada => AppColors.accent2;

  /// Text or a glyph drawn on a filled [onTime] shape: [AppColors.accent] is
  /// bright in both themes, so it always takes dark ink.
  static const onOnTime = Color(0xFF201404);

  /// Text or a glyph drawn on a filled [qada] shape: [AppColors.accent2] is
  /// tuned dark in both themes, so it always takes light ink.
  static const onQada = Color(0xFFF4EFE3);

  static Color of(PrayerLogStatus status) => switch (status) {
    PrayerLogStatus.onTime => onTime,
    PrayerLogStatus.qada => qada,
  };

  static Color onFillOf(PrayerLogStatus status) => switch (status) {
    PrayerLogStatus.onTime => onOnTime,
    PrayerLogStatus.qada => onQada,
  };
}
