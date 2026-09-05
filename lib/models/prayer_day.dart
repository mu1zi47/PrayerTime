import '../data/date_labels.dart';
import '../data/timezone_utils.dart';
import '../l10n/app_localizations.dart';

class PrayerDay {
  final DateTime date;
  final String fajr;
  final String sunrise;
  final String zuhr;
  final String asr;
  final String maghrib;
  final String isha;

  /// Start of the last third of the night — the time conventionally taken
  /// as Tahajjud, ending at this same record's [fajr] (see the API's
  /// "Lastthird" timing, which is why it's earlier in the clock than fajr
  /// despite belonging to the same day's record).
  final String tahajjud;

  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.zuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.tahajjud,
  });

  factory PrayerDay.fromApi(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final gregorian =
        (json['date'] as Map<String, dynamic>)['gregorian']
            as Map<String, dynamic>;
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
      tahajjud: clean('Lastthird'),
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

  final double latitude;
  final double longitude;

  /// IANA time zone name (e.g. "Asia/Tashkent"). May be empty for a
  /// just-picked custom city (search result / detected location) until the
  /// first prayer-times fetch resolves it from the API response.
  final String timeZone;

  /// True for a city the user found via search or "detect automatically"
  /// rather than one from [ReferenceData]'s curated list.
  final bool isCustom;

  const City({
    required this.id,
    required this.englishCity,
    required this.englishCountry,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    this.isCustom = false,
  });

  Duration get utcOffset => utcOffsetForTimeZone(timeZone);

  City withTimeZone(String timeZone) => City(
    id: id,
    englishCity: englishCity,
    englishCountry: englishCountry,
    latitude: latitude,
    longitude: longitude,
    timeZone: timeZone,
    isCustom: isCustom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'englishCity': englishCity,
    'englishCountry': englishCountry,
    'latitude': latitude,
    'longitude': longitude,
    'timeZone': timeZone,
    'isCustom': isCustom,
  };

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] as String,
    englishCity: json['englishCity'] as String,
    englishCountry: json['englishCountry'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timeZone: json['timeZone'] as String? ?? '',
    isCustom: json['isCustom'] as bool? ?? false,
  );

  /// A stable id for a city found via search/GPS rather than picked from the
  /// curated list — same rounded coordinates always produce the same id, so
  /// re-selecting the same spot is recognized as "already selected".
  static String customId(double latitude, double longitude) =>
      'custom:${latitude.toStringAsFixed(3)}:${longitude.toStringAsFixed(3)}';
}
