import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';

class ReferenceData {
  ReferenceData._();

  // Coordinates + IANA time zones back every entry so prayer times are
  // fetched from Aladhan's coordinate-based endpoint (works for literally
  // any point on Earth) and local time/DST is computed correctly — the same
  // path a searched or GPS-detected city goes through. Only the first dozen
  // (the original curated set) have fully localized names in every locale;
  // the rest fall back to their English name via [cityNameFor]/
  // [cityCountryFor], same as search results.
  static const List<City> cities = [
    City(
      id: 'moscow',
      englishCity: 'Moscow',
      englishCountry: 'Russia',
      latitude: 55.7558,
      longitude: 37.6173,
      timeZone: 'Europe/Moscow',
    ),
    City(
      id: 'kazan',
      englishCity: 'Kazan',
      englishCountry: 'Russia',
      latitude: 55.8304,
      longitude: 49.0661,
      timeZone: 'Europe/Moscow',
    ),
    City(
      id: 'ufa',
      englishCity: 'Ufa',
      englishCountry: 'Russia',
      latitude: 54.7388,
      longitude: 55.9721,
      timeZone: 'Asia/Yekaterinburg',
    ),
    City(
      id: 'grozny',
      englishCity: 'Grozny',
      englishCountry: 'Russia',
      latitude: 43.3169,
      longitude: 45.6981,
      timeZone: 'Europe/Moscow',
    ),
    City(
      id: 'makhachkala',
      englishCity: 'Makhachkala',
      englishCountry: 'Russia',
      latitude: 42.9849,
      longitude: 47.5047,
      timeZone: 'Europe/Moscow',
    ),
    City(
      id: 'istanbul',
      englishCity: 'Istanbul',
      englishCountry: 'Turkey',
      latitude: 41.0082,
      longitude: 28.9784,
      timeZone: 'Europe/Istanbul',
    ),
    City(
      id: 'cairo',
      englishCity: 'Cairo',
      englishCountry: 'Egypt',
      latitude: 30.0444,
      longitude: 31.2357,
      timeZone: 'Africa/Cairo',
    ),
    City(
      id: 'jakarta',
      englishCity: 'Jakarta',
      englishCountry: 'Indonesia',
      latitude: -6.2088,
      longitude: 106.8456,
      timeZone: 'Asia/Jakarta',
    ),
    City(
      id: 'tashkent',
      englishCity: 'Tashkent',
      englishCountry: 'Uzbekistan',
      latitude: 41.2995,
      longitude: 69.2401,
      timeZone: 'Asia/Tashkent',
    ),
    City(
      id: 'almaty',
      englishCity: 'Almaty',
      englishCountry: 'Kazakhstan',
      latitude: 43.2220,
      longitude: 76.8512,
      timeZone: 'Asia/Almaty',
    ),
    City(
      id: 'baku',
      englishCity: 'Baku',
      englishCountry: 'Azerbaijan',
      latitude: 40.4093,
      longitude: 49.8671,
      timeZone: 'Asia/Baku',
    ),
    City(
      id: 'mecca',
      englishCity: 'Mecca',
      englishCountry: 'Saudi Arabia',
      latitude: 21.3891,
      longitude: 39.8579,
      timeZone: 'Asia/Riyadh',
    ),

    // Holy cities, CIS-country capitals, and Uzbekistan's other major
    // cities — everything else in the world is reachable through the
    // search box (backed by Nominatim, see GeocodingService) instead of
    // being hardcoded here.
    City(
      id: 'medina',
      englishCity: 'Medina',
      englishCountry: 'Saudi Arabia',
      latitude: 24.5247,
      longitude: 39.5692,
      timeZone: 'Asia/Riyadh',
    ),
    City(
      id: 'minsk',
      englishCity: 'Minsk',
      englishCountry: 'Belarus',
      latitude: 53.9006,
      longitude: 27.5590,
      timeZone: 'Europe/Minsk',
    ),
    City(
      id: 'astana',
      englishCity: 'Astana',
      englishCountry: 'Kazakhstan',
      latitude: 51.1605,
      longitude: 71.4704,
      timeZone: 'Asia/Almaty',
    ),
    City(
      id: 'yerevan',
      englishCity: 'Yerevan',
      englishCountry: 'Armenia',
      latitude: 40.1792,
      longitude: 44.4991,
      timeZone: 'Asia/Yerevan',
    ),
    City(
      id: 'chisinau',
      englishCity: 'Chisinau',
      englishCountry: 'Moldova',
      latitude: 47.0105,
      longitude: 28.8638,
      timeZone: 'Europe/Chisinau',
    ),
    City(
      id: 'bishkek',
      englishCity: 'Bishkek',
      englishCountry: 'Kyrgyzstan',
      latitude: 42.8746,
      longitude: 74.5698,
      timeZone: 'Asia/Bishkek',
    ),
    City(
      id: 'dushanbe',
      englishCity: 'Dushanbe',
      englishCountry: 'Tajikistan',
      latitude: 38.5598,
      longitude: 68.7870,
      timeZone: 'Asia/Dushanbe',
    ),
    City(
      id: 'ashgabat',
      englishCity: 'Ashgabat',
      englishCountry: 'Turkmenistan',
      latitude: 37.9601,
      longitude: 58.3261,
      timeZone: 'Asia/Ashgabat',
    ),
    City(
      id: 'samarkand',
      englishCity: 'Samarkand',
      englishCountry: 'Uzbekistan',
      latitude: 39.6270,
      longitude: 66.9750,
      timeZone: 'Asia/Samarkand',
    ),
    City(
      id: 'bukhara',
      englishCity: 'Bukhara',
      englishCountry: 'Uzbekistan',
      latitude: 39.7747,
      longitude: 64.4286,
      timeZone: 'Asia/Samarkand',
    ),
    City(
      id: 'namangan',
      englishCity: 'Namangan',
      englishCountry: 'Uzbekistan',
      latitude: 40.9983,
      longitude: 71.6726,
      timeZone: 'Asia/Tashkent',
    ),
    City(
      id: 'andijan',
      englishCity: 'Andijan',
      englishCountry: 'Uzbekistan',
      latitude: 40.7833,
      longitude: 72.3333,
      timeZone: 'Asia/Tashkent',
    ),
  ];

  static const List<PrayerMethod> methods = [
    PrayerMethod(id: 'uzbekistan', aladhanCode: 2, tune: '0,-2,0,0,0,4,0,3,0'),
    PrayerMethod(id: 'karachi', aladhanCode: 1),
    PrayerMethod(id: 'isna', aladhanCode: 2),
    PrayerMethod(id: 'mwl', aladhanCode: 3),
    PrayerMethod(id: 'ummalqura', aladhanCode: 4),
    PrayerMethod(id: 'egypt', aladhanCode: 5),
    PrayerMethod(id: 'turkey', aladhanCode: 13),
  ];
}

/// The display name for [city] — fully localized for the curated set, and
/// the plain English/local name (as returned by search or GPS reverse-
/// geocoding) for anything found through the search box instead.
String cityNameFor(AppLocalizations t, City city) => switch (city.id) {
  'moscow' => t.cityMoscow,
  'kazan' => t.cityKazan,
  'ufa' => t.cityUfa,
  'grozny' => t.cityGrozny,
  'makhachkala' => t.cityMakhachkala,
  'istanbul' => t.cityIstanbul,
  'cairo' => t.cityCairo,
  'jakarta' => t.cityJakarta,
  'tashkent' => t.cityTashkent,
  'almaty' => t.cityAlmaty,
  'baku' => t.cityBaku,
  'mecca' => t.cityMecca,
  'medina' => t.cityMedina,
  'minsk' => t.cityMinsk,
  'astana' => t.cityAstana,
  'yerevan' => t.cityYerevan,
  'chisinau' => t.cityChisinau,
  'bishkek' => t.cityBishkek,
  'dushanbe' => t.cityDushanbe,
  'ashgabat' => t.cityAshgabat,
  'samarkand' => t.citySamarkand,
  'bukhara' => t.cityBukhara,
  'namangan' => t.cityNamangan,
  'andijan' => t.cityAndijan,
  _ => city.englishCity,
};

String cityCountryFor(AppLocalizations t, City city) => switch (city.id) {
  'moscow' || 'kazan' || 'ufa' || 'grozny' || 'makhachkala' => t.countryRussia,
  'istanbul' => t.countryTurkey,
  'cairo' => t.countryEgypt,
  'jakarta' => t.countryIndonesia,
  'tashkent' ||
  'samarkand' ||
  'bukhara' ||
  'namangan' ||
  'andijan' => t.countryUzbekistan,
  'almaty' || 'astana' => t.countryKazakhstan,
  'baku' => t.countryAzerbaijan,
  'mecca' || 'medina' => t.countrySaudiArabia,
  'minsk' => t.countryBelarus,
  'yerevan' => t.countryArmenia,
  'chisinau' => t.countryMoldova,
  'bishkek' => t.countryKyrgyzstan,
  'dushanbe' => t.countryTajikistan,
  'ashgabat' => t.countryTurkmenistan,
  _ => city.englishCountry,
};

String methodLabelFor(AppLocalizations t, String methodId) =>
    switch (methodId) {
      'uzbekistan' => t.methodUzbekistan,
      'karachi' => t.methodKarachi,
      'isna' => t.methodIsna,
      'mwl' => t.methodMwl,
      'ummalqura' => t.methodUmmAlQura,
      'egypt' => t.methodEgypt,
      'turkey' => t.methodTurkey,
      _ => methodId,
    };
