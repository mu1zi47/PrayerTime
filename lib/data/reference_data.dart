import '../models/prayer_day.dart';

/// Static reference data: the curated city list (used both for display and
/// for the Al Adhan API's `city`/`country` params) and calculation methods.
class ReferenceData {
  ReferenceData._();

  static const List<City> cities = [
    City(name: 'Москва', countryLabel: 'Россия', englishCity: 'Moscow', englishCountry: 'Russia', utcOffsetHours: 3),
    City(name: 'Казань', countryLabel: 'Россия', englishCity: 'Kazan', englishCountry: 'Russia', utcOffsetHours: 3),
    City(name: 'Уфа', countryLabel: 'Россия', englishCity: 'Ufa', englishCountry: 'Russia', utcOffsetHours: 5),
    City(name: 'Грозный', countryLabel: 'Россия', englishCity: 'Grozny', englishCountry: 'Russia', utcOffsetHours: 3),
    City(name: 'Махачкала', countryLabel: 'Россия', englishCity: 'Makhachkala', englishCountry: 'Russia', utcOffsetHours: 3),
    City(name: 'Стамбул', countryLabel: 'Турция', englishCity: 'Istanbul', englishCountry: 'Turkey', utcOffsetHours: 3),
    City(name: 'Каир', countryLabel: 'Египет', englishCity: 'Cairo', englishCountry: 'Egypt', utcOffsetHours: 2),
    City(name: 'Джакарта', countryLabel: 'Индонезия', englishCity: 'Jakarta', englishCountry: 'Indonesia', utcOffsetHours: 7),
    City(name: 'Ташкент', countryLabel: 'Узбекистан', englishCity: 'Tashkent', englishCountry: 'Uzbekistan', utcOffsetHours: 5),
    City(name: 'Алматы', countryLabel: 'Казахстан', englishCity: 'Almaty', englishCountry: 'Kazakhstan', utcOffsetHours: 6),
    City(name: 'Баку', countryLabel: 'Азербайджан', englishCity: 'Baku', englishCountry: 'Azerbaijan', utcOffsetHours: 4),
    City(name: 'Мекка', countryLabel: 'Саудовская Аравия', englishCity: 'Mecca', englishCountry: 'Saudi Arabia', utcOffsetHours: 3),
  ];

  static const List<PrayerMethod> methods = [
    PrayerMethod(id: 'mwl', label: 'Muslim World League', aladhanCode: 3),
    PrayerMethod(id: 'egypt', label: 'Египетское управление', aladhanCode: 5),
    PrayerMethod(id: 'karachi', label: 'Karachi (Ханафи)', aladhanCode: 1),
    PrayerMethod(id: 'ummalqura', label: 'Умм-эль-Кура', aladhanCode: 4),
    PrayerMethod(id: 'isna', label: 'ISNA', aladhanCode: 2),
  ];
}
