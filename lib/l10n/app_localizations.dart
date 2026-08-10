import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Latn'),
  ];

  /// No description provided for @navPrayer.
  ///
  /// In ru, this message translates to:
  /// **'Намаз'**
  String get navPrayer;

  /// No description provided for @navMore.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get navMore;

  /// No description provided for @navSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get navSettings;

  /// No description provided for @nextPrayerLabel.
  ///
  /// In ru, this message translates to:
  /// **'Следующий намаз'**
  String get nextPrayerLabel;

  /// No description provided for @todayLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get todayLabel;

  /// No description provided for @retryButton.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retryButton;

  /// No description provided for @prayerTimeLabel.
  ///
  /// In ru, this message translates to:
  /// **'Время намаза'**
  String get prayerTimeLabel;

  /// No description provided for @stopButton.
  ///
  /// In ru, this message translates to:
  /// **'Остановить'**
  String get stopButton;

  /// No description provided for @azanScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Азан'**
  String get azanScreenTitle;

  /// No description provided for @azanPlaceholderNote.
  ///
  /// In ru, this message translates to:
  /// **'Пока у всех чтецов звучит один и тот же временный сигнал — настоящие записи будут добавлены позже.'**
  String get azanPlaceholderNote;

  /// No description provided for @citySelectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выбор города'**
  String get citySelectTitle;

  /// No description provided for @citySearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск города'**
  String get citySearchHint;

  /// No description provided for @cityAutoDetect.
  ///
  /// In ru, this message translates to:
  /// **'Определить автоматически'**
  String get cityAutoDetect;

  /// No description provided for @cityMoscow.
  ///
  /// In ru, this message translates to:
  /// **'Москва'**
  String get cityMoscow;

  /// No description provided for @cityKazan.
  ///
  /// In ru, this message translates to:
  /// **'Казань'**
  String get cityKazan;

  /// No description provided for @cityUfa.
  ///
  /// In ru, this message translates to:
  /// **'Уфа'**
  String get cityUfa;

  /// No description provided for @cityGrozny.
  ///
  /// In ru, this message translates to:
  /// **'Грозный'**
  String get cityGrozny;

  /// No description provided for @cityMakhachkala.
  ///
  /// In ru, this message translates to:
  /// **'Махачкала'**
  String get cityMakhachkala;

  /// No description provided for @cityIstanbul.
  ///
  /// In ru, this message translates to:
  /// **'Стамбул'**
  String get cityIstanbul;

  /// No description provided for @cityCairo.
  ///
  /// In ru, this message translates to:
  /// **'Каир'**
  String get cityCairo;

  /// No description provided for @cityJakarta.
  ///
  /// In ru, this message translates to:
  /// **'Джакарта'**
  String get cityJakarta;

  /// No description provided for @cityTashkent.
  ///
  /// In ru, this message translates to:
  /// **'Ташкент'**
  String get cityTashkent;

  /// No description provided for @cityAlmaty.
  ///
  /// In ru, this message translates to:
  /// **'Алматы'**
  String get cityAlmaty;

  /// No description provided for @cityBaku.
  ///
  /// In ru, this message translates to:
  /// **'Баку'**
  String get cityBaku;

  /// No description provided for @cityMecca.
  ///
  /// In ru, this message translates to:
  /// **'Мекка'**
  String get cityMecca;

  /// No description provided for @countryRussia.
  ///
  /// In ru, this message translates to:
  /// **'Россия'**
  String get countryRussia;

  /// No description provided for @countryTurkey.
  ///
  /// In ru, this message translates to:
  /// **'Турция'**
  String get countryTurkey;

  /// No description provided for @countryEgypt.
  ///
  /// In ru, this message translates to:
  /// **'Египет'**
  String get countryEgypt;

  /// No description provided for @countryIndonesia.
  ///
  /// In ru, this message translates to:
  /// **'Индонезия'**
  String get countryIndonesia;

  /// No description provided for @countryUzbekistan.
  ///
  /// In ru, this message translates to:
  /// **'Узбекистан'**
  String get countryUzbekistan;

  /// No description provided for @countryKazakhstan.
  ///
  /// In ru, this message translates to:
  /// **'Казахстан'**
  String get countryKazakhstan;

  /// No description provided for @countryAzerbaijan.
  ///
  /// In ru, this message translates to:
  /// **'Азербайджан'**
  String get countryAzerbaijan;

  /// No description provided for @countrySaudiArabia.
  ///
  /// In ru, this message translates to:
  /// **'Саудовская Аравия'**
  String get countrySaudiArabia;

  /// No description provided for @methodScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Метод расчёта'**
  String get methodScreenTitle;

  /// No description provided for @methodUzbekistan.
  ///
  /// In ru, this message translates to:
  /// **'Управление мусульман Узбекистана'**
  String get methodUzbekistan;

  /// No description provided for @methodKarachi.
  ///
  /// In ru, this message translates to:
  /// **'Исламский университет, Карачи'**
  String get methodKarachi;

  /// No description provided for @methodIsna.
  ///
  /// In ru, this message translates to:
  /// **'Исламское общество Северной Америки'**
  String get methodIsna;

  /// No description provided for @methodMwl.
  ///
  /// In ru, this message translates to:
  /// **'Всемирная мусульманская лига'**
  String get methodMwl;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In ru, this message translates to:
  /// **'Умм Аль-Кура, Мекка'**
  String get methodUmmAlQura;

  /// No description provided for @methodEgypt.
  ///
  /// In ru, this message translates to:
  /// **'Главное управление Египта'**
  String get methodEgypt;

  /// No description provided for @methodTurkey.
  ///
  /// In ru, this message translates to:
  /// **'Министерство по делам религии Турции'**
  String get methodTurkey;

  /// No description provided for @languageScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageScreenTitle;

  /// No description provided for @allahNamesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Имена Аллаха'**
  String get allahNamesTitle;

  /// No description provided for @myPrayersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои намазы'**
  String get myPrayersTitle;

  /// No description provided for @allahNamesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Аль-Асма уль-Хусна'**
  String get allahNamesSubtitle;

  /// No description provided for @tabAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get tabAll;

  /// No description provided for @tabFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get tabFavorites;

  /// No description provided for @nothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get nothingFound;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся имена, добавленные в избранное'**
  String get favoritesEmpty;

  /// No description provided for @namesSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по номеру, имени, значению'**
  String get namesSearchHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get descriptionLabel;

  /// No description provided for @notificationsScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notificationsScreenTitle;

  /// No description provided for @azanByPrayersKicker.
  ///
  /// In ru, this message translates to:
  /// **'Азан по намазам'**
  String get azanByPrayersKicker;

  /// No description provided for @soundKicker.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get soundKicker;

  /// No description provided for @azanSoundRow.
  ///
  /// In ru, this message translates to:
  /// **'Азан — {reciter}'**
  String azanSoundRow(String reciter);

  /// No description provided for @reciterAbdulbasit.
  ///
  /// In ru, this message translates to:
  /// **'Абдульбасит Абдуссамат'**
  String get reciterAbdulbasit;

  /// No description provided for @reciterAknazar.
  ///
  /// In ru, this message translates to:
  /// **'Акназар Маратулы'**
  String get reciterAknazar;

  /// No description provided for @reciterAliAhmedMulla.
  ///
  /// In ru, this message translates to:
  /// **'Али Ахмед Мулла'**
  String get reciterAliAhmedMulla;

  /// No description provided for @reciterAhmedAlNufais.
  ///
  /// In ru, this message translates to:
  /// **'Ахмед аль-Нуфайс'**
  String get reciterAhmedAlNufais;

  /// No description provided for @reciterBaubek.
  ///
  /// In ru, this message translates to:
  /// **'Баубек Бердыгалиулы'**
  String get reciterBaubek;

  /// No description provided for @reciterMustafaIsmail.
  ///
  /// In ru, this message translates to:
  /// **'Мустафа Исмаил'**
  String get reciterMustafaIsmail;

  /// No description provided for @reciterMishari.
  ///
  /// In ru, this message translates to:
  /// **'Мишари Рашид аль-Афаси'**
  String get reciterMishari;

  /// No description provided for @reciterMustafaOzcan.
  ///
  /// In ru, this message translates to:
  /// **'Мустафа Осджан Гунешдогды'**
  String get reciterMustafaOzcan;

  /// No description provided for @reciterMansurZahrani.
  ///
  /// In ru, this message translates to:
  /// **'Мансур аз-Захрани'**
  String get reciterMansurZahrani;

  /// No description provided for @reciterNasirQatami.
  ///
  /// In ru, this message translates to:
  /// **'Насир аль-Катами'**
  String get reciterNasirQatami;

  /// No description provided for @reciterRaadKurdi.
  ///
  /// In ru, this message translates to:
  /// **'Раад Мухаммад аль-Курди'**
  String get reciterRaadKurdi;

  /// No description provided for @reciterSaidmuhammed.
  ///
  /// In ru, this message translates to:
  /// **'Саидмухаммед Ныгмат'**
  String get reciterSaidmuhammed;

  /// No description provided for @reciterNoteTakbirShort.
  ///
  /// In ru, this message translates to:
  /// **'такбир, короткая версия'**
  String get reciterNoteTakbirShort;

  /// No description provided for @reciterNoteStudioRecording.
  ///
  /// In ru, this message translates to:
  /// **'студийная запись'**
  String get reciterNoteStudioRecording;

  /// No description provided for @quietKicker.
  ///
  /// In ru, this message translates to:
  /// **'Тишина'**
  String get quietKicker;

  /// No description provided for @dontDisturbNight.
  ///
  /// In ru, this message translates to:
  /// **'Не беспокоить ночью'**
  String get dontDisturbNight;

  /// No description provided for @nowBarScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Now Bar'**
  String get nowBarScreenTitle;

  /// No description provided for @nowBarAvailability.
  ///
  /// In ru, this message translates to:
  /// **'Доступно только на Samsung с One UI 7 и выше'**
  String get nowBarAvailability;

  /// No description provided for @nowBarShowCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Показывать текущий намаз'**
  String get nowBarShowCurrent;

  /// No description provided for @nowBarShowNext.
  ///
  /// In ru, this message translates to:
  /// **'Показывать следующий намаз'**
  String get nowBarShowNext;

  /// No description provided for @nowBarAllowPermission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить показ в Now Bar'**
  String get nowBarAllowPermission;

  /// No description provided for @myPrayersSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отмечайте прочитанные намазы'**
  String get myPrayersSubtitle;

  /// No description provided for @prayerLogDone.
  ///
  /// In ru, this message translates to:
  /// **'Выполнено {done} из {total}'**
  String prayerLogDone(int done, int total);

  /// No description provided for @prayerLogLateSuffix.
  ///
  /// In ru, this message translates to:
  /// **' · Не вовремя: {count}'**
  String prayerLogLateSuffix(int count);

  /// No description provided for @notYetDue.
  ///
  /// In ru, this message translates to:
  /// **'Ещё не наступил'**
  String get notYetDue;

  /// No description provided for @statusOnTime.
  ///
  /// In ru, this message translates to:
  /// **'Вовремя'**
  String get statusOnTime;

  /// No description provided for @statusLate.
  ///
  /// In ru, this message translates to:
  /// **'Не вовремя'**
  String get statusLate;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsScreenTitle;

  /// No description provided for @cityKicker.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get cityKicker;

  /// No description provided for @madhabKicker.
  ///
  /// In ru, this message translates to:
  /// **'Мазхаб (расчёт Аср)'**
  String get madhabKicker;

  /// No description provided for @madhabShafi.
  ///
  /// In ru, this message translates to:
  /// **'Шафии'**
  String get madhabShafi;

  /// No description provided for @madhabHanafi.
  ///
  /// In ru, this message translates to:
  /// **'Ханафи'**
  String get madhabHanafi;

  /// No description provided for @azanAndReminders.
  ///
  /// In ru, this message translates to:
  /// **'Азан и напоминания'**
  String get azanAndReminders;

  /// No description provided for @nowBarSettingsRow.
  ///
  /// In ru, this message translates to:
  /// **'Текущий и следующий намаз'**
  String get nowBarSettingsRow;

  /// No description provided for @themeKicker.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get themeKicker;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get themeSystem;

  /// No description provided for @prayerFajr.
  ///
  /// In ru, this message translates to:
  /// **'Фаджр'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In ru, this message translates to:
  /// **'Восход'**
  String get prayerSunrise;

  /// No description provided for @prayerZuhr.
  ///
  /// In ru, this message translates to:
  /// **'Зухр'**
  String get prayerZuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ru, this message translates to:
  /// **'Аср'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ru, this message translates to:
  /// **'Магриб'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ru, this message translates to:
  /// **'Иша'**
  String get prayerIsha;

  /// No description provided for @weekdayShortMon.
  ///
  /// In ru, this message translates to:
  /// **'Пн'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In ru, this message translates to:
  /// **'Вт'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In ru, this message translates to:
  /// **'Ср'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In ru, this message translates to:
  /// **'Чт'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In ru, this message translates to:
  /// **'Пт'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In ru, this message translates to:
  /// **'Сб'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In ru, this message translates to:
  /// **'Вс'**
  String get weekdayShortSun;

  /// No description provided for @weekdayFullMon.
  ///
  /// In ru, this message translates to:
  /// **'понедельник'**
  String get weekdayFullMon;

  /// No description provided for @weekdayFullTue.
  ///
  /// In ru, this message translates to:
  /// **'вторник'**
  String get weekdayFullTue;

  /// No description provided for @weekdayFullWed.
  ///
  /// In ru, this message translates to:
  /// **'среда'**
  String get weekdayFullWed;

  /// No description provided for @weekdayFullThu.
  ///
  /// In ru, this message translates to:
  /// **'четверг'**
  String get weekdayFullThu;

  /// No description provided for @weekdayFullFri.
  ///
  /// In ru, this message translates to:
  /// **'пятница'**
  String get weekdayFullFri;

  /// No description provided for @weekdayFullSat.
  ///
  /// In ru, this message translates to:
  /// **'суббота'**
  String get weekdayFullSat;

  /// No description provided for @weekdayFullSun.
  ///
  /// In ru, this message translates to:
  /// **'воскресенье'**
  String get weekdayFullSun;

  /// No description provided for @month01.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get month01;

  /// No description provided for @month02.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get month02;

  /// No description provided for @month03.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get month03;

  /// No description provided for @month04.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get month04;

  /// No description provided for @month05.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get month05;

  /// No description provided for @month06.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get month06;

  /// No description provided for @month07.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get month07;

  /// No description provided for @month08.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get month08;

  /// No description provided for @month09.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get month09;

  /// No description provided for @month10.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get month12;

  /// No description provided for @countdownHoursMinutes.
  ///
  /// In ru, this message translates to:
  /// **'через {hours} ч {minutes} мин'**
  String countdownHoursMinutes(int hours, int minutes);

  /// No description provided for @countdownHoursOnly.
  ///
  /// In ru, this message translates to:
  /// **'через {hours} ч'**
  String countdownHoursOnly(int hours);

  /// No description provided for @countdownMinutesOnly.
  ///
  /// In ru, this message translates to:
  /// **'через {minutes} мин'**
  String countdownMinutesOnly(int minutes);

  /// No description provided for @notifAzanTitle.
  ///
  /// In ru, this message translates to:
  /// **'Азан — {prayer}'**
  String notifAzanTitle(String prayer);

  /// No description provided for @notifPlainTitle.
  ///
  /// In ru, this message translates to:
  /// **'Наступил намаз {prayer}'**
  String notifPlainTitle(String prayer);

  /// No description provided for @notifBody.
  ///
  /// In ru, this message translates to:
  /// **'Время совершить намаз'**
  String get notifBody;

  /// No description provided for @nowBarNotificationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Намаз'**
  String get nowBarNotificationTitle;

  /// No description provided for @nowBarCurrentLine.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас: {prayer}'**
  String nowBarCurrentLine(String prayer);

  /// No description provided for @nowBarNextLine.
  ///
  /// In ru, this message translates to:
  /// **'Далее: {prayer} в {time}'**
  String nowBarNextLine(String prayer, String time);

  /// No description provided for @errorTimeout.
  ///
  /// In ru, this message translates to:
  /// **'Превышено время ожидания. Проверьте интернет-соединение.'**
  String get errorTimeout;

  /// No description provided for @errorNoConnection.
  ///
  /// In ru, this message translates to:
  /// **'Нет соединения с интернетом.'**
  String get errorNoConnection;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сервис времён намаза временно недоступен.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorParseFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось разобрать ответ сервиса.'**
  String get errorParseFailed;

  /// No description provided for @errorFetchFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить времена намаза.'**
  String get errorFetchFailed;

  /// No description provided for @genericLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить времена намаза.'**
  String get genericLoadError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsUzCyrl();
          case 'Latn':
            return AppLocalizationsUzLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
