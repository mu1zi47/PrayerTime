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

  /// Parses one entry of Al Adhan's `calendarByCity` response `data` array.
  /// Timing strings like `"16:37 (MSK)"` are trimmed to just `"16:37"`.
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

  static const _weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _weekdayFull = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];
  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  String get weekdayShort => _weekdayShort[date.weekday - 1];

  String get weekdayFull => _weekdayFull[date.weekday - 1];

  String get weekdayFullCapitalized =>
      weekdayFull[0].toUpperCase() + weekdayFull.substring(1);

  String get dayNumber => '${date.day}';

  String get dateLabel => '${date.day} ${_months[date.month - 1]}';

  String get fullLabel => '$dateLabel, $weekdayFull';
}

class PrayerMethod {
  final String id;
  final String label;

  /// Al Adhan API's numeric calculation-method code.
  final int aladhanCode;

  const PrayerMethod({required this.id, required this.label, required this.aladhanCode});
}

class City {
  /// Display name (Russian).
  final String name;

  /// Display subtitle — the country, in Russian.
  final String countryLabel;

  /// City/country strings as Al Adhan expects them (English).
  final String englishCity;
  final String englishCountry;

  /// Fixed UTC offset in hours, used to compute "now" in this city's local
  /// time (Al Adhan returns already-localized HH:mm strings, so comparing
  /// against the device's own clock would be wrong for a city in a
  /// different timezone than the device). Ignores DST — none of the
  /// currently listed cities observe it, but worth knowing if that changes.
  final int utcOffsetHours;

  const City({
    required this.name,
    required this.countryLabel,
    required this.englishCity,
    required this.englishCountry,
    required this.utcOffsetHours,
  });
}
