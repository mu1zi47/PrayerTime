// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navMore => 'More';

  @override
  String get navSettings => 'Settings';

  @override
  String get nextPrayerLabel => 'Next prayer';

  @override
  String get todayLabel => 'Today';

  @override
  String get retryButton => 'Retry';

  @override
  String get prayerTimeLabel => 'Prayer time';

  @override
  String get stopButton => 'Stop';

  @override
  String get azanScreenTitle => 'Azan';

  @override
  String get azanPlaceholderNote =>
      'For now every reciter plays the same placeholder sound — real recordings will be added later.';

  @override
  String get citySelectTitle => 'Choose a city';

  @override
  String get citySearchHint => 'Search city';

  @override
  String get cityAutoDetect => 'Detect automatically';

  @override
  String get cityMoscow => 'Moscow';

  @override
  String get cityKazan => 'Kazan';

  @override
  String get cityUfa => 'Ufa';

  @override
  String get cityGrozny => 'Grozny';

  @override
  String get cityMakhachkala => 'Makhachkala';

  @override
  String get cityIstanbul => 'Istanbul';

  @override
  String get cityCairo => 'Cairo';

  @override
  String get cityJakarta => 'Jakarta';

  @override
  String get cityTashkent => 'Tashkent';

  @override
  String get cityAlmaty => 'Almaty';

  @override
  String get cityBaku => 'Baku';

  @override
  String get cityMecca => 'Mecca';

  @override
  String get countryRussia => 'Russia';

  @override
  String get countryTurkey => 'Turkey';

  @override
  String get countryEgypt => 'Egypt';

  @override
  String get countryIndonesia => 'Indonesia';

  @override
  String get countryUzbekistan => 'Uzbekistan';

  @override
  String get countryKazakhstan => 'Kazakhstan';

  @override
  String get countryAzerbaijan => 'Azerbaijan';

  @override
  String get countrySaudiArabia => 'Saudi Arabia';

  @override
  String get methodScreenTitle => 'Calculation method';

  @override
  String get methodUzbekistan => 'Muslim Board of Uzbekistan';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodIsna => 'Islamic Society of North America';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodUmmAlQura => 'Umm Al-Qura University, Makkah';

  @override
  String get methodEgypt => 'Egyptian General Authority of Survey';

  @override
  String get methodTurkey => 'Turkey Diyanet (Presidency of Religious Affairs)';

  @override
  String get languageScreenTitle => 'Language';

  @override
  String get allahNamesTitle => 'Names of Allah';

  @override
  String get myPrayersTitle => 'My prayers';

  @override
  String get allahNamesSubtitle => 'Al-Asma-ul-Husna';

  @override
  String get tabAll => 'All';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get favoritesEmpty => 'Names you add to favorites will show up here';

  @override
  String get namesSearchHint => 'Search by number, name, meaning';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get azanByPrayersKicker => 'Azan per prayer';

  @override
  String get soundKicker => 'Sound';

  @override
  String azanSoundRow(String reciter) {
    return 'Azan — $reciter';
  }

  @override
  String get reciterAbdulbasit => 'Abdul Basit Abdul Samad';

  @override
  String get reciterAknazar => 'Aknazar Maratuly';

  @override
  String get reciterAliAhmedMulla => 'Ali Ahmed Mulla';

  @override
  String get reciterAhmedAlNufais => 'Ahmed Al Nufais';

  @override
  String get reciterBaubek => 'Baubek Berdygaliuly';

  @override
  String get reciterMustafaIsmail => 'Mustafa Ismail';

  @override
  String get reciterMishari => 'Mishary Rashid Alafasy';

  @override
  String get reciterMustafaOzcan => 'Mustafa Ozcan Gunesdogdu';

  @override
  String get reciterMansurZahrani => 'Mansour Al Zahrani';

  @override
  String get reciterNasirQatami => 'Nasser Al Qatami';

  @override
  String get reciterRaadKurdi => 'Raad Mohammad Al Kurdi';

  @override
  String get reciterSaidmuhammed => 'Saidmuhammed Nygmat';

  @override
  String get reciterNoteTakbirShort => 'takbir, short version';

  @override
  String get reciterNoteStudioRecording => 'studio recording';

  @override
  String get quietKicker => 'Quiet hours';

  @override
  String get dontDisturbNight => 'Do not disturb at night';

  @override
  String get nowBarScreenTitle => 'Now Bar';

  @override
  String get nowBarAvailability =>
      'Available only on Samsung with One UI 7 and up';

  @override
  String get nowBarShowCurrent => 'Show current prayer';

  @override
  String get nowBarShowNext => 'Show next prayer';

  @override
  String get nowBarAllowPermission => 'Allow showing in Now Bar';

  @override
  String get myPrayersSubtitle => 'Mark the prayers you\'ve prayed';

  @override
  String prayerLogDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String prayerLogLateSuffix(int count) {
    return ' · Late: $count';
  }

  @override
  String get notYetDue => 'Not yet due';

  @override
  String get statusOnTime => 'On time';

  @override
  String get statusLate => 'Late';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get cityKicker => 'City';

  @override
  String get madhabKicker => 'Madhab (Asr calculation)';

  @override
  String get madhabShafi => 'Shafi\'i';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get azanAndReminders => 'Azan & reminders';

  @override
  String get nowBarSettingsRow => 'Current & next prayer';

  @override
  String get themeKicker => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerZuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get weekdayShortMon => 'Mon';

  @override
  String get weekdayShortTue => 'Tue';

  @override
  String get weekdayShortWed => 'Wed';

  @override
  String get weekdayShortThu => 'Thu';

  @override
  String get weekdayShortFri => 'Fri';

  @override
  String get weekdayShortSat => 'Sat';

  @override
  String get weekdayShortSun => 'Sun';

  @override
  String get weekdayFullMon => 'Monday';

  @override
  String get weekdayFullTue => 'Tuesday';

  @override
  String get weekdayFullWed => 'Wednesday';

  @override
  String get weekdayFullThu => 'Thursday';

  @override
  String get weekdayFullFri => 'Friday';

  @override
  String get weekdayFullSat => 'Saturday';

  @override
  String get weekdayFullSun => 'Sunday';

  @override
  String get month01 => 'January';

  @override
  String get month02 => 'February';

  @override
  String get month03 => 'March';

  @override
  String get month04 => 'April';

  @override
  String get month05 => 'May';

  @override
  String get month06 => 'June';

  @override
  String get month07 => 'July';

  @override
  String get month08 => 'August';

  @override
  String get month09 => 'September';

  @override
  String get month10 => 'October';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'December';

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return 'in ${hours}h ${minutes}m';
  }

  @override
  String countdownHoursOnly(int hours) {
    return 'in ${hours}h';
  }

  @override
  String countdownMinutesOnly(int minutes) {
    return 'in ${minutes}m';
  }

  @override
  String notifAzanTitle(String prayer) {
    return 'Azan — $prayer';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer prayer time';
  }

  @override
  String get notifBody => 'Time to pray';

  @override
  String get nowBarNotificationTitle => 'Prayer';

  @override
  String nowBarCurrentLine(String prayer) {
    return 'Now: $prayer';
  }

  @override
  String nowBarNextLine(String prayer, String time) {
    return 'Next: $prayer at $time';
  }

  @override
  String get errorTimeout =>
      'Request timed out. Check your internet connection.';

  @override
  String get errorNoConnection => 'No internet connection.';

  @override
  String get errorServiceUnavailable =>
      'The prayer times service is temporarily unavailable.';

  @override
  String get errorParseFailed => 'Couldn\'t parse the service response.';

  @override
  String get errorFetchFailed => 'Couldn\'t fetch prayer times.';

  @override
  String get genericLoadError => 'Couldn\'t load prayer times.';
}
