import 'package:flutter/material.dart';

/// The six salah times, in display order — matches `.pray-ic` icon
/// choices from the design (rounded stroke icons per prayer).
enum PrayerKind { fajr, sunrise, zuhr, asr, maghrib, isha }

IconData iconForPrayer(PrayerKind kind) {
  switch (kind) {
    case PrayerKind.fajr:
      return Icons.wb_twilight_rounded;
    case PrayerKind.sunrise:
      return Icons.wb_sunny_outlined;
    case PrayerKind.zuhr:
      return Icons.wb_sunny_rounded;
    case PrayerKind.asr:
      return Icons.light_mode_rounded;
    case PrayerKind.maghrib:
      return Icons.nights_stay_outlined;
    case PrayerKind.isha:
      return Icons.nightlight_round;
  }
}

String nameForPrayer(PrayerKind kind) {
  switch (kind) {
    case PrayerKind.fajr:
      return 'Фаджр';
    case PrayerKind.sunrise:
      return 'Восход';
    case PrayerKind.zuhr:
      return 'Зухр';
    case PrayerKind.asr:
      return 'Аср';
    case PrayerKind.maghrib:
      return 'Магриб';
    case PrayerKind.isha:
      return 'Иша';
  }
}

String arabicForPrayer(PrayerKind kind) {
  switch (kind) {
    case PrayerKind.fajr:
      return 'الفجر';
    case PrayerKind.sunrise:
      return 'الشروق';
    case PrayerKind.zuhr:
      return 'الظهر';
    case PrayerKind.asr:
      return 'العصر';
    case PrayerKind.maghrib:
      return 'المغرب';
    case PrayerKind.isha:
      return 'العشاء';
  }
}
