import '../data/date_labels.dart';
import '../l10n/app_localizations.dart';

class PrayerDay {
  final DateTime date;
  final String fajr;
  final String sunrise;
  final String zuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.zuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerDay.fromApi(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final gregorian = (json['date'] as Map<String, dynamic>)['gregorian'] as Map<String, dynamic>;
    final month = gregorian['month'] as Map<String, dynamic>;

    String clean(String key) => (timings[key] as String).split(' ').first;

    return PrayerDay(
      date: DateTime(
        int.parse(gregorian['year'] as String),
        int.parse(month['number'].toString()),
        int.parse(gregorian['day'] as String),
      ),
      fajr: clean('Fajr'),
      sunrise: clean('Sunrise'),
      zuhr: clean('Dhuhr'),
      asr: clean('Asr'),
      maghrib: clean('Maghrib'),
      isha: clean('Isha'),
    );
  }

  String weekdayShort(AppLocalizations t) => DateLabels.shortWeekday(t, date);

  String weekdayFull(AppLocalizations t) => DateLabels.fullWeekday(t, date);

  String weekdayFullCapitalized(AppLocalizations t) {
    final w = weekdayFull(t);
    return w[0].toUpperCase() + w.substring(1);
  }

  String get dayNumber => '${date.day}';

  String dateLabel(AppLocalizations t) => DateLabels.dateLabel(t, date);

  String fullLabel(AppLocalizations t) => DateLabels.fullLabel(t, date);
}

class PrayerMethod {
  final String id;

  final int aladhanCode;

  final String? tune;

  const PrayerMethod({required this.id, required this.aladhanCode, this.tune});
}

class City {
  final String id;

  final String englishCity;
  final String englishCountry;

  final int utcOffsetHours;

  const City({
    required this.id,
    required this.englishCity,
    required this.englishCountry,
    required this.utcOffsetHours,
  });
}
