import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';

class ReferenceData {
  ReferenceData._();

  static const List<City> cities = [
    City(id: 'moscow', englishCity: 'Moscow', englishCountry: 'Russia', utcOffsetHours: 3),
    City(id: 'kazan', englishCity: 'Kazan', englishCountry: 'Russia', utcOffsetHours: 3),
    City(id: 'ufa', englishCity: 'Ufa', englishCountry: 'Russia', utcOffsetHours: 5),
    City(id: 'grozny', englishCity: 'Grozny', englishCountry: 'Russia', utcOffsetHours: 3),
    City(id: 'makhachkala', englishCity: 'Makhachkala', englishCountry: 'Russia', utcOffsetHours: 3),
    City(id: 'istanbul', englishCity: 'Istanbul', englishCountry: 'Turkey', utcOffsetHours: 3),
    City(id: 'cairo', englishCity: 'Cairo', englishCountry: 'Egypt', utcOffsetHours: 2),
    City(id: 'jakarta', englishCity: 'Jakarta', englishCountry: 'Indonesia', utcOffsetHours: 7),
    City(id: 'tashkent', englishCity: 'Tashkent', englishCountry: 'Uzbekistan', utcOffsetHours: 5),
    City(id: 'almaty', englishCity: 'Almaty', englishCountry: 'Kazakhstan', utcOffsetHours: 6),
    City(id: 'baku', englishCity: 'Baku', englishCountry: 'Azerbaijan', utcOffsetHours: 4),
    City(id: 'mecca', englishCity: 'Mecca', englishCountry: 'Saudi Arabia', utcOffsetHours: 3),
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

String cityNameFor(AppLocalizations t, String cityId) => switch (cityId) {
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
      _ => cityId,
    };

String cityCountryFor(AppLocalizations t, String cityId) => switch (cityId) {
      'moscow' || 'kazan' || 'ufa' || 'grozny' || 'makhachkala' => t.countryRussia,
      'istanbul' => t.countryTurkey,
      'cairo' => t.countryEgypt,
      'jakarta' => t.countryIndonesia,
      'tashkent' => t.countryUzbekistan,
      'almaty' => t.countryKazakhstan,
      'baku' => t.countryAzerbaijan,
      'mecca' => t.countrySaudiArabia,
      _ => '',
    };

String methodLabelFor(AppLocalizations t, String methodId) => switch (methodId) {
      'uzbekistan' => t.methodUzbekistan,
      'karachi' => t.methodKarachi,
      'isna' => t.methodIsna,
      'mwl' => t.methodMwl,
      'ummalqura' => t.methodUmmAlQura,
      'egypt' => t.methodEgypt,
      'turkey' => t.methodTurkey,
      _ => methodId,
    };
