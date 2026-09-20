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
  String nextPrayerTomorrowLabel(String date) {
    return 'Завтра, $date';
  }

  @override
  String yesterdayCurrentLabel(String date) {
    return 'Вчера, $date';
  }

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get retryButton => 'Повторить';

  @override
  String get prayerTimeLabel => 'Время намаза';

  @override
  String get stopButton => 'Остановить';

  @override
  String get citySelectTitle => 'Выбор города';

  @override
  String get citySearchHint => 'Поиск города';

  @override
  String get cityAutoDetect => 'Определить автоматически';

  @override
  String get cityAutoDetecting => 'Определяем ваше местоположение…';

  @override
  String get cityCurrentLocation => 'Текущее местоположение';

  @override
  String get cityLocationServiceDisabled =>
      'Включите геолокацию в настройках устройства';

  @override
  String get cityLocationPermissionDenied =>
      'Нет доступа к геолокации. Разрешите доступ в настройках';

  @override
  String get cityLocationErrorGeneric => 'Не удалось определить местоположение';

  @override
  String get cityOpenSettingsButton => 'Открыть настройки';

  @override
  String get cityOnlineResultsTitle => 'Найдено онлайн';

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
  String get cityMedina => 'Медина';

  @override
  String get cityMinsk => 'Минск';

  @override
  String get cityAstana => 'Астана';

  @override
  String get cityYerevan => 'Ереван';

  @override
  String get cityChisinau => 'Кишинёв';

  @override
  String get cityBishkek => 'Бишкек';

  @override
  String get cityDushanbe => 'Душанбе';

  @override
  String get cityAshgabat => 'Ашхабад';

  @override
  String get citySamarkand => 'Самарканд';

  @override
  String get cityBukhara => 'Бухара';

  @override
  String get cityNamangan => 'Наманган';

  @override
  String get cityAndijan => 'Андижан';

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
  String get countryBelarus => 'Беларусь';

  @override
  String get countryArmenia => 'Армения';

  @override
  String get countryMoldova => 'Молдова';

  @override
  String get countryKyrgyzstan => 'Киргизия';

  @override
  String get countryTajikistan => 'Таджикистан';

  @override
  String get countryTurkmenistan => 'Туркменистан';

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
  String get azanByPrayersKicker => 'Уведомления по намазам';

  @override
  String get quietKicker => 'Тишина';

  @override
  String get dontDisturbNight => 'Не беспокоить ночью';

  @override
  String logSheetTitle(String prayer) {
    return 'Как прошёл $prayer?';
  }

  @override
  String get logSheetSubtitle => 'Отметьте, как вы совершили этот намаз';

  @override
  String get logSheetOnTime => 'Прочитал вовремя';

  @override
  String get logSheetLate => 'Прочитал с опозданием';

  @override
  String get logSheetClear => 'Убрать отметку';

  @override
  String get settingsScreenTitle => 'Настройки';

  @override
  String get prayerSettingsTitle => 'Время намаза';

  @override
  String get systemSettingsTitle => 'Системные настройки';

  @override
  String get cityKicker => 'Город';

  @override
  String get madhabKicker => 'Мазхаб (расчёт Аср)';

  @override
  String get madhabShafi => 'Шафии';

  @override
  String get madhabHanafi => 'Ханафи';

  @override
  String get azanAndReminders => 'Уведомления и напоминания';

  @override
  String get themeKicker => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeSystem => 'Системная';

  @override
  String get tahajjudKicker => 'Тахаджуд-намаз';

  @override
  String get tahajjudEnableRow => 'Показывать тахаджуд-намаз';

  @override
  String get prayerTahajjud => 'Тахаджуд';

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
  String notifPlainTitle(String prayer) {
    return 'Наступил намаз $prayer';
  }

  @override
  String get notifBody => 'Время совершить намаз';

  @override
  String get notifMarkDoneAction => 'Прочитал';

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

  @override
  String get errorOfflineSettingsChange =>
      'Чтобы изменить эти настройки, нужно подключение к интернету.';

  @override
  String get calendarScreenTitle => 'Календарь намазов';

  @override
  String get legendOnTime => 'Вовремя';

  @override
  String get legendQada => 'С опозданием';

  @override
  String get legendMissed => 'Пропущено';

  @override
  String get notifEveningReminderTitle => 'Не забудьте отметить намазы';

  @override
  String get notifEveningReminderBody =>
      'Загляните в приложение и отметьте, как прошёл сегодняшний день';

  @override
  String notifPrayerEndingTitle(String prayer) {
    return 'Время намаза $prayer заканчивается';
  }

  @override
  String notifPrayerEndingBody(int minutes) {
    return 'Осталось $minutes мин, а намаз ещё не отмечен как прочитанный';
  }

  @override
  String get widgetMarkedLabel => 'Прочитано';

  @override
  String get widgetNoDataLabel => 'Откройте приложение';

  @override
  String get nowBarTitle => 'Now Bar';

  @override
  String get persistentNotifTitle => 'Постоянное уведомление';

  @override
  String get nowBarDescription => 'Текущий намаз будет показываться в Now Bar.';

  @override
  String get persistentNotifDescription =>
      'Текущий намаз будет показываться в уведомлениях.';

  @override
  String get nowBarSwitchLabel => 'Показывать в Now Bar';

  @override
  String get persistentNotifSwitchLabel => 'Показывать уведомление';

  @override
  String get infoButtonLabel => 'Подробнее';

  @override
  String get nowBarOn => 'Вкл';

  @override
  String get nowBarOff => 'Выкл';

  @override
  String get nowBarNotificationsOff =>
      'Уведомления для приложения выключены в настройках телефона, поэтому оно не появится.';

  @override
  String get nowBarOpenSettings => 'Открыть настройки телефона';

  @override
  String get nowBarOpenAction => 'Открыть';

  @override
  String get nowBarEndsIn => 'До конца';

  @override
  String get nowBarStartsIn => 'До начала';

  @override
  String get nowBarChannelName => 'Текущий намаз';

  @override
  String get nowBarScheduleLabel => 'Показывать все намазы';

  @override
  String get nowBarScheduleDescription =>
      'Все намазы будут показываться в Now Bar.';

  @override
  String get nowBarScheduleDescriptionPlain =>
      'Все намазы будут показываться в уведомлениях.';

  @override
  String get nowBarDevTitle => 'Now Bar пока выключен на этом телефоне';

  @override
  String get nowBarDevBody =>
      'Samsung пускает сторонние приложения в Now Bar только после того, как включён переключатель в меню «Для разработчиков». До этого намаз будет обычным уведомлением.';

  @override
  String get nowBarDevStepAbout =>
      'Откройте «Настройки» → «Сведения о телефоне» → «Сведения о ПО».';

  @override
  String get nowBarDevStepBuildNumber =>
      'Нажмите на «Номер сборки» 7 раз подряд и подтвердите PIN-кодом, если телефон попросит. Появится меню «Для разработчиков».';

  @override
  String get nowBarDevStepDeveloperOptions =>
      'Вернитесь в «Настройки» и откройте «Для разработчиков» — в самом низу списка.';

  @override
  String get nowBarDevStepSwitch =>
      'Найдите «Живые уведомл. для всех прилож.» и включите переключатель.';

  @override
  String get nowBarDevOpenAbout => 'Открыть «Сведения о телефоне»';

  @override
  String get nowBarDevOpenDeveloper => 'Открыть «Для разработчиков»';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingBack => 'Назад';

  @override
  String get onboardingFinish => 'Готово';

  @override
  String get onboardingLanguageTitle => 'Язык приложения';

  @override
  String get onboardingLanguageBody =>
      'Выберите язык: на нём будут названия намазов, подсказки и уведомления. Поменять можно в любой момент в настройках.';

  @override
  String get onboardingThemeTitle => 'Оформление';

  @override
  String get onboardingThemeBody =>
      'Светлое, тёмное или как на телефоне. Виджет на главном экране следует этому же выбору.';

  @override
  String get onboardingCityTitle => 'Ваш город';

  @override
  String get onboardingCityBody =>
      'Время намазов зависит от координат, поэтому город — самая важная настройка. Определите его автоматически или выберите вручную.';

  @override
  String get onboardingCityDetect => 'Определить автоматически';

  @override
  String get onboardingCityManual => 'Выбрать вручную';

  @override
  String get onboardingCitySelected => 'Выбран город';

  @override
  String get onboardingMethodTitle => 'Метод расчёта';

  @override
  String get onboardingMethodBody =>
      'Организации считают фаджр и ишу по разным углам солнца, поэтому время отличается на несколько минут. Выберите метод, принятый в вашей местности.';

  @override
  String get onboardingMadhabTitle => 'Мазхаб';

  @override
  String get onboardingMadhabBody =>
      'От мазхаба зависит только время аср: у ханафитов оно наступает позже, чем у шафиитов.';

  @override
  String get onboardingNotifTitle => 'Уведомления';

  @override
  String get onboardingNotifBody =>
      'Приложение напомнит о наступлении намаза и ещё раз за 30 минут до конца его времени, если намаз не отмечен как прочитанный.';

  @override
  String get notifModeSound => 'Со звуком';

  @override
  String get notifModeSilent => 'Без звука';

  @override
  String get notifModeOff => 'Выключено';

  @override
  String get calendarNotMarked => 'Не отмечен';

  @override
  String get calendarDayPanelKicker => 'Отметьте намазы';

  @override
  String get namesNoticeTitle => 'Пока только на узбекском';

  @override
  String get namesNoticeBody =>
      'Имена Аллаха и их толкования сейчас доступны только на узбекском (кириллица). Переводы на другие языки появятся в одном из следующих обновлений.';

  @override
  String get namesNoticeButton => 'Понятно';

  @override
  String get feedbackKicker => 'Обратная связь';

  @override
  String get feedbackEmail => 'Написать на почту';

  @override
  String get feedbackTelegram => 'Написать в Telegram';

  @override
  String get feedbackCopied => 'Скопировано';

  @override
  String appVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get namesNoticeDisclaimer =>
      'Возможны неточности в написании и толкованиях. Если заметите ошибку — напишите нам через раздел «Обратная связь» в настройках.';

  @override
  String get namesDisclaimerTitle => 'Обратите внимание';
}
