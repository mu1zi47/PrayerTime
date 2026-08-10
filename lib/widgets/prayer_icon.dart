import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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

/// [t] is an [AppLocalizations] instance — from `AppLocalizations.of(context)!`
/// in a widget build method, or from `lookupAppLocalizations(locale)`
/// anywhere without a BuildContext (see AppState, NotificationService).
String nameForPrayer(AppLocalizations t, PrayerKind kind) {
  switch (kind) {
    case PrayerKind.fajr:
      return t.prayerFajr;
    case PrayerKind.sunrise:
      return t.prayerSunrise;
    case PrayerKind.zuhr:
      return t.prayerZuhr;
    case PrayerKind.asr:
      return t.prayerAsr;
    case PrayerKind.maghrib:
      return t.prayerMaghrib;
    case PrayerKind.isha:
      return t.prayerIsha;
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
