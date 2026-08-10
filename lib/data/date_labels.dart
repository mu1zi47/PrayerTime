import '../l10n/app_localizations.dart';

/// Weekday/month labels for an arbitrary [DateTime], in whichever language
/// [t] resolves to — shared by [PrayerDay] (API-fetched upcoming days) and
/// [PrayerLogScreen] (which needs the same labels for arbitrary past dates
/// the API never covers).
class DateLabels {
  DateLabels._();

  static List<String> _weekdayShort(AppLocalizations t) => [
        t.weekdayShortMon,
        t.weekdayShortTue,
        t.weekdayShortWed,
        t.weekdayShortThu,
        t.weekdayShortFri,
        t.weekdayShortSat,
        t.weekdayShortSun,
      ];

  static List<String> _weekdayFull(AppLocalizations t) => [
        t.weekdayFullMon,
        t.weekdayFullTue,
        t.weekdayFullWed,
        t.weekdayFullThu,
        t.weekdayFullFri,
        t.weekdayFullSat,
        t.weekdayFullSun,
      ];

  static List<String> _months(AppLocalizations t) => [
        t.month01,
        t.month02,
        t.month03,
        t.month04,
        t.month05,
        t.month06,
        t.month07,
        t.month08,
        t.month09,
        t.month10,
        t.month11,
        t.month12,
      ];

  static String shortWeekday(AppLocalizations t, DateTime d) => _weekdayShort(t)[d.weekday - 1];

  static String fullWeekday(AppLocalizations t, DateTime d) => _weekdayFull(t)[d.weekday - 1];

  static String dateLabel(AppLocalizations t, DateTime d) => '${d.day} ${_months(t)[d.month - 1]}';

  static String fullLabel(AppLocalizations t, DateTime d) => '${dateLabel(t, d)}, ${fullWeekday(t, d)}';
}
