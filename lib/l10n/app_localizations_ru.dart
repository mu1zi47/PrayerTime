// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navPrayer => 'Намаз';

  @override
  String get navMore => 'Ещё';

  @override
  String get navSettings => 'Настройки';

  @override
  String get nextPrayerLabel => 'Следующий намаз';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get retryButton => 'Повторить';

  @override
  String get prayerTimeLabel => 'Время намаза';

  @override
  String get stopButton => 'Остановить';

  @override
  String get azanScreenTitle => 'Азан';

  @override
  String get azanPlaceholderNote =>
      'Пока у всех чтецов звучит один и тот же временный сигнал — настоящие записи будут добавлены позже.';

  @override
  String get citySelectTitle => 'Выбор города';

  @override
  String get citySearchHint => 'Поиск города';

  @override
  String get cityAutoDetect => 'Определить автоматически';

  @override
  String get cityMoscow => 'Москва';

  @override
  String get cityKazan => 'Казань';

  @override
  String get cityUfa => 'Уфа';

  @override
  String get cityGrozny => 'Грозный';

  @override
  String get cityMakhachkala => 'Махачкала';

  @override
  String get cityIstanbul => 'Стамбул';

  @override
  String get cityCairo => 'Каир';

  @override
  String get cityJakarta => 'Джакарта';

  @override
  String get cityTashkent => 'Ташкент';

  @override
  String get cityAlmaty => 'Алматы';

  @override
  String get cityBaku => 'Баку';

  @override
  String get cityMecca => 'Мекка';

  @override
  String get countryRussia => 'Россия';

  @override
  String get countryTurkey => 'Турция';

  @override
  String get countryEgypt => 'Египет';

  @override
  String get countryIndonesia => 'Индонезия';

  @override
  String get countryUzbekistan => 'Узбекистан';

  @override
  String get countryKazakhstan => 'Казахстан';

  @override
  String get countryAzerbaijan => 'Азербайджан';

  @override
  String get countrySaudiArabia => 'Саудовская Аравия';

  @override
  String get methodScreenTitle => 'Метод расчёта';

  @override
  String get methodUzbekistan => 'Управление мусульман Узбекистана';

  @override
  String get methodKarachi => 'Исламский университет, Карачи';

  @override
  String get methodIsna => 'Исламское общество Северной Америки';

  @override
  String get methodMwl => 'Всемирная мусульманская лига';

  @override
  String get methodUmmAlQura => 'Умм Аль-Кура, Мекка';

  @override
  String get methodEgypt => 'Главное управление Египта';

  @override
  String get methodTurkey => 'Министерство по делам религии Турции';

  @override
  String get languageScreenTitle => 'Язык';

  @override
  String get allahNamesTitle => 'Имена Аллаха';

  @override
  String get myPrayersTitle => 'Мои намазы';

  @override
  String get allahNamesSubtitle => 'Аль-Асма уль-Хусна';

  @override
  String get tabAll => 'Все';

  @override
  String get tabFavorites => 'Избранное';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get favoritesEmpty => 'Здесь появятся имена, добавленные в избранное';

  @override
  String get namesSearchHint => 'Поиск по номеру, имени, значению';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get notificationsScreenTitle => 'Уведомления';

  @override
  String get azanByPrayersKicker => 'Азан по намазам';

  @override
  String get soundKicker => 'Звук';

  @override
  String azanSoundRow(String reciter) {
    return 'Азан — $reciter';
  }

  @override
  String get reciterAbdulbasit => 'Абдульбасит Абдуссамат';

  @override
  String get reciterAknazar => 'Акназар Маратулы';

  @override
  String get reciterAliAhmedMulla => 'Али Ахмед Мулла';

  @override
  String get reciterAhmedAlNufais => 'Ахмед аль-Нуфайс';

  @override
  String get reciterBaubek => 'Баубек Бердыгалиулы';

  @override
  String get reciterMustafaIsmail => 'Мустафа Исмаил';

  @override
  String get reciterMishari => 'Мишари Рашид аль-Афаси';

  @override
  String get reciterMustafaOzcan => 'Мустафа Осджан Гунешдогды';

  @override
  String get reciterMansurZahrani => 'Мансур аз-Захрани';

  @override
  String get reciterNasirQatami => 'Насир аль-Катами';

  @override
  String get reciterRaadKurdi => 'Раад Мухаммад аль-Курди';

  @override
  String get reciterSaidmuhammed => 'Саидмухаммед Ныгмат';

  @override
  String get reciterNoteTakbirShort => 'такбир, короткая версия';

  @override
  String get reciterNoteStudioRecording => 'студийная запись';

  @override
  String get quietKicker => 'Тишина';

  @override
  String get dontDisturbNight => 'Не беспокоить ночью';

  @override
  String get nowBarScreenTitle => 'Now Bar';

  @override
  String get nowBarAvailability =>
      'Доступно только на Samsung с One UI 7 и выше';

  @override
  String get nowBarShowCurrent => 'Показывать текущий намаз';

  @override
  String get nowBarShowNext => 'Показывать следующий намаз';

  @override
  String get nowBarAllowPermission => 'Разрешить показ в Now Bar';

  @override
  String get myPrayersSubtitle => 'Отмечайте прочитанные намазы';

  @override
  String prayerLogDone(int done, int total) {
    return 'Выполнено $done из $total';
  }

  @override
  String prayerLogLateSuffix(int count) {
    return ' · Не вовремя: $count';
  }

  @override
  String get notYetDue => 'Ещё не наступил';

  @override
  String get statusOnTime => 'Вовремя';

  @override
  String get statusLate => 'Не вовремя';

  @override
  String get settingsScreenTitle => 'Настройки';

  @override
  String get cityKicker => 'Город';

  @override
  String get madhabKicker => 'Мазхаб (расчёт Аср)';

  @override
  String get madhabShafi => 'Шафии';

  @override
  String get madhabHanafi => 'Ханафи';

  @override
  String get azanAndReminders => 'Азан и напоминания';

  @override
  String get nowBarSettingsRow => 'Текущий и следующий намаз';

  @override
  String get themeKicker => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get prayerFajr => 'Фаджр';

  @override
  String get prayerSunrise => 'Восход';

  @override
  String get prayerZuhr => 'Зухр';

  @override
  String get prayerAsr => 'Аср';

  @override
  String get prayerMaghrib => 'Магриб';

  @override
  String get prayerIsha => 'Иша';

  @override
  String get weekdayShortMon => 'Пн';

  @override
  String get weekdayShortTue => 'Вт';

  @override
  String get weekdayShortWed => 'Ср';

  @override
  String get weekdayShortThu => 'Чт';

  @override
  String get weekdayShortFri => 'Пт';

  @override
  String get weekdayShortSat => 'Сб';

  @override
  String get weekdayShortSun => 'Вс';

  @override
  String get weekdayFullMon => 'понедельник';

  @override
  String get weekdayFullTue => 'вторник';

  @override
  String get weekdayFullWed => 'среда';

  @override
  String get weekdayFullThu => 'четверг';

  @override
  String get weekdayFullFri => 'пятница';

  @override
  String get weekdayFullSat => 'суббота';

  @override
  String get weekdayFullSun => 'воскресенье';

  @override
  String get month01 => 'января';

  @override
  String get month02 => 'февраля';

  @override
  String get month03 => 'марта';

  @override
  String get month04 => 'апреля';

  @override
  String get month05 => 'мая';

  @override
  String get month06 => 'июня';

  @override
  String get month07 => 'июля';

  @override
  String get month08 => 'августа';

  @override
  String get month09 => 'сентября';

  @override
  String get month10 => 'октября';

  @override
  String get month11 => 'ноября';

  @override
  String get month12 => 'декабря';

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return 'через $hours ч $minutes мин';
  }

  @override
  String countdownHoursOnly(int hours) {
    return 'через $hours ч';
  }

  @override
  String countdownMinutesOnly(int minutes) {
    return 'через $minutes мин';
  }

  @override
  String notifAzanTitle(String prayer) {
    return 'Азан — $prayer';
  }

  @override
  String notifPlainTitle(String prayer) {
    return 'Наступил намаз $prayer';
  }

  @override
  String get notifBody => 'Время совершить намаз';

  @override
  String get nowBarNotificationTitle => 'Намаз';

  @override
  String nowBarCurrentLine(String prayer) {
    return 'Сейчас: $prayer';
  }

  @override
  String nowBarNextLine(String prayer, String time) {
    return 'Далее: $prayer в $time';
  }

  @override
  String get errorTimeout =>
      'Превышено время ожидания. Проверьте интернет-соединение.';

  @override
  String get errorNoConnection => 'Нет соединения с интернетом.';

  @override
  String get errorServiceUnavailable =>
      'Сервис времён намаза временно недоступен.';

  @override
  String get errorParseFailed => 'Не удалось разобрать ответ сервиса.';

  @override
  String get errorFetchFailed => 'Не удалось получить времена намаза.';

  @override
  String get genericLoadError => 'Не удалось загрузить времена намаза.';
}
