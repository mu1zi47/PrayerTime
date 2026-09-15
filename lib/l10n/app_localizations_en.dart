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
  String nextPrayerTomorrowLabel(String date) {
    return 'Tomorrow, $date';
  }

  @override
  String yesterdayCurrentLabel(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get retryButton => 'Retry';

  @override
  String get prayerTimeLabel => 'Prayer time';

  @override
  String get stopButton => 'Stop';

  @override
  String get citySelectTitle => 'Choose a city';

  @override
  String get citySearchHint => 'Search city';

  @override
  String get cityAutoDetect => 'Detect automatically';

  @override
  String get cityAutoDetecting => 'Detecting your location…';

  @override
  String get cityCurrentLocation => 'Current location';

  @override
  String get cityLocationServiceDisabled =>
      'Turn on location services in your device settings';

  @override
  String get cityLocationPermissionDenied =>
      'Location access denied. Allow it in settings';

  @override
  String get cityLocationErrorGeneric => 'Couldn\'t determine your location';

  @override
  String get cityOpenSettingsButton => 'Open settings';

  @override
  String get cityOnlineResultsTitle => 'Found online';

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
  String get cityMedina => 'Medina';

  @override
  String get cityMinsk => 'Minsk';

  @override
  String get cityAstana => 'Astana';

  @override
  String get cityYerevan => 'Yerevan';

  @override
  String get cityChisinau => 'Chisinau';

  @override
  String get cityBishkek => 'Bishkek';

  @override
  String get cityDushanbe => 'Dushanbe';

  @override
  String get cityAshgabat => 'Ashgabat';

  @override
  String get citySamarkand => 'Samarkand';

  @override
  String get cityBukhara => 'Bukhara';

  @override
  String get cityNamangan => 'Namangan';

  @override
  String get cityAndijan => 'Andijan';

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
  String get countryBelarus => 'Belarus';

  @override
  String get countryArmenia => 'Armenia';

  @override
  String get countryMoldova => 'Moldova';

  @override
  String get countryKyrgyzstan => 'Kyrgyzstan';

  @override
  String get countryTajikistan => 'Tajikistan';

  @override
  String get countryTurkmenistan => 'Turkmenistan';

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
  String get azanByPrayersKicker => 'Notifications per prayer';

  @override
  String get quietKicker => 'Quiet hours';

  @override
  String get dontDisturbNight => 'Do not disturb at night';

  @override
  String logSheetTitle(String prayer) {
    return 'How did $prayer go?';
  }

  @override
  String get logSheetSubtitle => 'Mark how you prayed this one';

  @override
  String get logSheetOnTime => 'Prayed on time';

  @override
  String get logSheetLate => 'Prayed late';

  @override
  String get logSheetClear => 'Clear this mark';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get prayerSettingsTitle => 'Prayer times';

  @override
  String get systemSettingsTitle => 'System settings';

  @override
  String get cityKicker => 'City';

  @override
  String get madhabKicker => 'Madhab (Asr calculation)';

  @override
  String get madhabShafi => 'Shafi\'i';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get azanAndReminders => 'Notifications & reminders';

  @override
  String get themeKicker => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get tahajjudKicker => 'Tahajjud prayer';

  @override
  String get tahajjudEnableRow => 'Show Tahajjud prayer';

  @override
  String get prayerTahajjud => 'Tahajjud';

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
  String notifPlainTitle(String prayer) {
    return '$prayer prayer time';
  }

  @override
  String get notifBody => 'Time to pray';

  @override
  String get notifMarkDoneAction => 'Done';

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

  @override
  String get errorOfflineSettingsChange =>
      'An internet connection is required to change these settings.';

  @override
  String get calendarScreenTitle => 'Prayer calendar';

  @override
  String get legendOnTime => 'On time';

  @override
  String get legendQada => 'Late';

  @override
  String get legendMissed => 'Missed';

  @override
  String get notifEveningReminderTitle => 'Don\'t forget to log your prayers';

  @override
  String get notifEveningReminderBody =>
      'Open the app and mark how today\'s prayers went';

  @override
  String notifPrayerEndingTitle(String prayer) {
    return '$prayer is almost over';
  }

  @override
  String notifPrayerEndingBody(int minutes) {
    return '$minutes min left, and this prayer still isn\'t marked as prayed';
  }

  @override
  String get widgetMarkedLabel => 'Logged';

  @override
  String get widgetNoDataLabel => 'Open the app';

  @override
  String get nowBarTitle => 'Now Bar';

  @override
  String get persistentNotifTitle => 'Persistent notification';

  @override
  String get nowBarDescription =>
      'Now Bar is the Samsung panel at the bottom of the lock screen and at the top of the notification panel. It shows the current prayer, how long until it ends, the next prayer, and a button to log the prayer without opening the app.';

  @override
  String get persistentNotifDescription =>
      'A notification pinned to the notification panel: the current prayer, how long until it ends, the next prayer, and a button to log the prayer without opening the app. Swiping it away brings it back — it can only be turned off here.';

  @override
  String get nowBarSwitchLabel => 'Show';

  @override
  String get nowBarOn => 'On';

  @override
  String get nowBarOff => 'Off';

  @override
  String get nowBarNotificationsOff =>
      'Notifications for this app are turned off in phone settings, so it won\'t appear.';

  @override
  String get nowBarOpenSettings => 'Open phone settings';

  @override
  String get nowBarUnmarkAction => 'Undo';

  @override
  String get nowBarEndsIn => 'Ends in';

  @override
  String get nowBarStartsIn => 'Starts in';

  @override
  String get nowBarChannelName => 'Current prayer';

  @override
  String get nowBarDevTitle => 'Now Bar is still off on this phone';

  @override
  String get nowBarDevBody =>
      'Samsung only lets other apps into the Now Bar once a switch in Developer options is on. Until then, the prayer shows as a regular notification.';

  @override
  String get nowBarDevStepAbout =>
      'Open Settings → About phone → Software information.';

  @override
  String get nowBarDevStepBuildNumber =>
      'Tap Build number 7 times in a row and confirm with your PIN if asked. Developer options will appear.';

  @override
  String get nowBarDevStepDeveloperOptions =>
      'Go back to Settings and open Developer options, at the very bottom of the list.';

  @override
  String get nowBarDevStepSwitch =>
      'Find “Live notifications for all apps” and turn it on.';

  @override
  String get nowBarDevOpenAbout => 'Open About phone';

  @override
  String get nowBarDevOpenDeveloper => 'Open Developer options';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Done';

  @override
  String get onboardingLanguageTitle => 'App language';

  @override
  String get onboardingLanguageBody =>
      'The language for prayer names, hints and notifications. You can change it any time in settings.';

  @override
  String get onboardingThemeTitle => 'Appearance';

  @override
  String get onboardingThemeBody =>
      'Light, dark, or whatever your phone uses. The home-screen widget follows this too.';

  @override
  String get onboardingCityTitle => 'Your city';

  @override
  String get onboardingCityBody =>
      'Prayer times depend on coordinates, so the city matters more than anything else here. Detect it automatically or pick it yourself.';

  @override
  String get onboardingCityDetect => 'Detect automatically';

  @override
  String get onboardingCityManual => 'Choose manually';

  @override
  String get onboardingCitySelected => 'Selected city';

  @override
  String get onboardingMethodTitle => 'Calculation method';

  @override
  String get onboardingMethodBody =>
      'Organizations use different sun angles for Fajr and Isha, so the times differ by a few minutes. Pick the one followed where you live.';

  @override
  String get onboardingMadhabTitle => 'Madhab';

  @override
  String get onboardingMadhabBody =>
      'This only affects Asr: in the Hanafi school it starts later than in the Shafi one.';

  @override
  String get onboardingNotifTitle => 'Notifications';

  @override
  String get onboardingNotifBody =>
      'The app announces each prayer, and reminds you again 30 minutes before its window closes if you haven\'t marked it as prayed.';

  @override
  String get notifModeSound => 'With sound';

  @override
  String get notifModeSilent => 'Silent';

  @override
  String get notifModeOff => 'Off';

  @override
  String get calendarNotMarked => 'Not marked';

  @override
  String get calendarDayPanelKicker => 'Mark the prayers';

  @override
  String get namesNoticeTitle => 'Uzbek only for now';

  @override
  String get namesNoticeBody =>
      'The names of Allah and their commentary are currently available in Uzbek (Cyrillic) only. Translations into other languages are coming in a future update.';

  @override
  String get namesNoticeButton => 'Got it';

  @override
  String get feedbackKicker => 'Feedback';

  @override
  String get feedbackEmail => 'Send an email';

  @override
  String get feedbackTelegram => 'Message on Telegram';

  @override
  String get feedbackCopied => 'Copied';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get namesNoticeDisclaimer =>
      'Spellings and commentary may contain mistakes. If you spot one, write to us through Feedback in settings.';

  @override
  String get namesDisclaimerTitle => 'Please note';
}
