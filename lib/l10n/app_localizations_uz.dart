// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get navPrayer => 'Namoz';

  @override
  String get navMore => 'Yana';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get nextPrayerLabel => 'Keyingi namoz';

  @override
  String nextPrayerTomorrowLabel(String date) {
    return 'Ertaga, $date';
  }

  @override
  String yesterdayCurrentLabel(String date) {
    return 'Kecha, $date';
  }

  @override
  String get todayLabel => 'Bugun';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get prayerTimeLabel => 'Namoz vaqti';

  @override
  String get stopButton => 'To\'xtatish';

  @override
  String get citySelectTitle => 'Shaharni tanlash';

  @override
  String get citySearchHint => 'Shahar qidirish';

  @override
  String get cityAutoDetect => 'Avtomatik aniqlash';

  @override
  String get cityAutoDetecting => 'Joylashuvingiz aniqlanmoqda…';

  @override
  String get cityCurrentLocation => 'Joriy joylashuv';

  @override
  String get cityLocationServiceDisabled =>
      'Qurilma sozlamalarida geolokatsiyani yoqing';

  @override
  String get cityLocationPermissionDenied =>
      'Geolokatsiyaga ruxsat berilmagan. Sozlamalarda ruxsat bering';

  @override
  String get cityLocationErrorGeneric => 'Joylashuvni aniqlab bo\'lmadi';

  @override
  String get cityOpenSettingsButton => 'Sozlamalarni ochish';

  @override
  String get cityOnlineResultsTitle => 'Internetdan topildi';

  @override
  String get cityMoscow => 'Moskva';

  @override
  String get cityKazan => 'Qozon';

  @override
  String get cityUfa => 'Ufa';

  @override
  String get cityGrozny => 'Grozniy';

  @override
  String get cityMakhachkala => 'Maxachqala';

  @override
  String get cityIstanbul => 'Istanbul';

  @override
  String get cityCairo => 'Qohira';

  @override
  String get cityJakarta => 'Jakarta';

  @override
  String get cityTashkent => 'Toshkent';

  @override
  String get cityAlmaty => 'Almati';

  @override
  String get cityBaku => 'Boku';

  @override
  String get cityMecca => 'Makka';

  @override
  String get cityMedina => 'Madina';

  @override
  String get cityMinsk => 'Minsk';

  @override
  String get cityAstana => 'Ostona';

  @override
  String get cityYerevan => 'Yerevan';

  @override
  String get cityChisinau => 'Kishinyov';

  @override
  String get cityBishkek => 'Bishkek';

  @override
  String get cityDushanbe => 'Dushanbe';

  @override
  String get cityAshgabat => 'Ashxobod';

  @override
  String get citySamarkand => 'Samarqand';

  @override
  String get cityBukhara => 'Buxoro';

  @override
  String get cityNamangan => 'Namangan';

  @override
  String get cityAndijan => 'Andijon';

  @override
  String get countryRussia => 'Rossiya';

  @override
  String get countryTurkey => 'Turkiya';

  @override
  String get countryEgypt => 'Misr';

  @override
  String get countryIndonesia => 'Indoneziya';

  @override
  String get countryUzbekistan => 'O\'zbekiston';

  @override
  String get countryKazakhstan => 'Qozog\'iston';

  @override
  String get countryAzerbaijan => 'Ozarbayjon';

  @override
  String get countrySaudiArabia => 'Saudiya Arabistoni';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryArmenia => 'Armaniston';

  @override
  String get countryMoldova => 'Moldova';

  @override
  String get countryKyrgyzstan => 'Qirg\'iziston';

  @override
  String get countryTajikistan => 'Tojikiston';

  @override
  String get countryTurkmenistan => 'Turkmaniston';

  @override
  String get methodScreenTitle => 'Hisoblash usuli';

  @override
  String get methodUzbekistan => 'O\'zbekiston musulmonlari idorasi';

  @override
  String get methodKarachi => 'Islom fanlari universiteti, Karachi';

  @override
  String get methodIsna => 'Shimoliy Amerika Islom jamiyati';

  @override
  String get methodMwl => 'Butunjahon musulmonlar ligasi';

  @override
  String get methodUmmAlQura => 'Umm al-Qura universiteti, Makka';

  @override
  String get methodEgypt => 'Misr Bosh boshqarmasi';

  @override
  String get methodTurkey => 'Turkiya Diniy ishlar boshqarmasi';

  @override
  String get languageScreenTitle => 'Til';

  @override
  String get allahNamesTitle => 'Allohning ismlari';

  @override
  String get allahNamesSubtitle => 'Asmaul Husna';

  @override
  String get tabAll => 'Barchasi';

  @override
  String get tabFavorites => 'Tanlanganlar';

  @override
  String get nothingFound => 'Hech narsa topilmadi';

  @override
  String get favoritesEmpty =>
      'Tanlanganlarga qo\'shilgan ismlar shu yerda ko\'rinadi';

  @override
  String get namesSearchHint => 'Raqami, nomi, ma\'nosi bo\'yicha qidirish';

  @override
  String get descriptionLabel => 'Ta\'rif';

  @override
  String get notificationsScreenTitle => 'Bildirishnomalar';

  @override
  String get azanByPrayersKicker => 'Har namoz uchun bildirishnoma';

  @override
  String get quietKicker => 'Jimlik';

  @override
  String get dontDisturbNight => 'Kechasi bezovta qilmaslik';

  @override
  String logSheetTitle(String prayer) {
    return '$prayer qanday o\'tdi?';
  }

  @override
  String get logSheetSubtitle => 'Bu namozni qanday o\'qiganingizni belgilang';

  @override
  String get logSheetOnTime => 'O\'z vaqtida o\'qidim';

  @override
  String get logSheetLate => 'Kechikib o\'qidim';

  @override
  String get logSheetClear => 'Belgini olib tashlash';

  @override
  String get settingsScreenTitle => 'Sozlamalar';

  @override
  String get prayerSettingsTitle => 'Namoz vaqti';

  @override
  String get systemSettingsTitle => 'Tizim sozlamalari';

  @override
  String get cityKicker => 'Shahar';

  @override
  String get madhabKicker => 'Mazhab (Asr hisobi)';

  @override
  String get madhabShafi => 'Shofi\'iy';

  @override
  String get madhabHanafi => 'Hanafiy';

  @override
  String get azanAndReminders => 'Bildirishnomalar va eslatmalar';

  @override
  String get themeKicker => 'Mavzu';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get themeSystem => 'Tizim';

  @override
  String get tahajjudKicker => 'Tahajjud namozi';

  @override
  String get tahajjudEnableRow => 'Tahajjud namozini ko\'rsatish';

  @override
  String get prayerTahajjud => 'Tahajjud';

  @override
  String get prayerFajr => 'Bomdod';

  @override
  String get prayerSunrise => 'Quyosh chiqishi';

  @override
  String get prayerZuhr => 'Peshin';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Shom';

  @override
  String get prayerIsha => 'Xufton';

  @override
  String get weekdayShortMon => 'Du';

  @override
  String get weekdayShortTue => 'Se';

  @override
  String get weekdayShortWed => 'Cho';

  @override
  String get weekdayShortThu => 'Pa';

  @override
  String get weekdayShortFri => 'Ju';

  @override
  String get weekdayShortSat => 'Sha';

  @override
  String get weekdayShortSun => 'Yak';

  @override
  String get weekdayFullMon => 'dushanba';

  @override
  String get weekdayFullTue => 'seshanba';

  @override
  String get weekdayFullWed => 'chorshanba';

  @override
  String get weekdayFullThu => 'payshanba';

  @override
  String get weekdayFullFri => 'juma';

  @override
  String get weekdayFullSat => 'shanba';

  @override
  String get weekdayFullSun => 'yakshanba';

  @override
  String get month01 => 'yanvar';

  @override
  String get month02 => 'fevral';

  @override
  String get month03 => 'mart';

  @override
  String get month04 => 'aprel';

  @override
  String get month05 => 'may';

  @override
  String get month06 => 'iyun';

  @override
  String get month07 => 'iyul';

  @override
  String get month08 => 'avgust';

  @override
  String get month09 => 'sentabr';

  @override
  String get month10 => 'oktabr';

  @override
  String get month11 => 'noyabr';

  @override
  String get month12 => 'dekabr';

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return '$hours soat $minutes daqiqadan so\'ng';
  }

  @override
  String countdownHoursOnly(int hours) {
    return '$hours soatdan so\'ng';
  }

  @override
  String countdownMinutesOnly(int minutes) {
    return '$minutes daqiqadan so\'ng';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer namozi vaqti bo\'ldi';
  }

  @override
  String get notifBody => 'Namoz o\'qish vaqti';

  @override
  String get notifMarkDoneAction => 'Bajardim';

  @override
  String get errorTimeout =>
      'Kutish vaqti tugadi. Internet aloqasini tekshiring.';

  @override
  String get errorNoConnection => 'Internet aloqasi yo\'q.';

  @override
  String get errorServiceUnavailable =>
      'Namoz vaqtlari xizmati vaqtincha ishlamayapti.';

  @override
  String get errorParseFailed => 'Xizmat javobini qayta ishlab bo\'lmadi.';

  @override
  String get errorFetchFailed => 'Namoz vaqtlarini olib bo\'lmadi.';

  @override
  String get genericLoadError => 'Namoz vaqtlarini yuklab bo\'lmadi.';

  @override
  String get errorOfflineSettingsChange =>
      'Ushbu sozlamalarni o\'zgartirish uchun internet ulanishi kerak.';

  @override
  String get calendarScreenTitle => 'Namoz taqvimi';

  @override
  String get legendOnTime => 'O\'z vaqtida';

  @override
  String get legendQada => 'Kechikib';

  @override
  String get legendMissed => 'O\'tkazib yuborilgan';

  @override
  String get notifEveningReminderTitle =>
      'Namozlaringizni belgilashni unutmang';

  @override
  String get notifEveningReminderBody =>
      'Ilovaga kirib, bugungi namozlaringiz qanday o\'tganini belgilang';

  @override
  String notifPrayerEndingTitle(String prayer) {
    return '$prayer vaqti tugayapti';
  }

  @override
  String notifPrayerEndingBody(int minutes) {
    return '$minutes daqiqa qoldi, namoz hali o\'qilgan deb belgilanmagan';
  }

  @override
  String get widgetMarkedLabel => 'Belgilandi';

  @override
  String get widgetNoDataLabel => 'Ilovani oching';
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get navPrayer => 'Намоз';

  @override
  String get navMore => 'Яна';

  @override
  String get navSettings => 'Созламалар';

  @override
  String get nextPrayerLabel => 'Кейинги намоз';

  @override
  String nextPrayerTomorrowLabel(String date) {
    return 'Эртага, $date';
  }

  @override
  String yesterdayCurrentLabel(String date) {
    return 'Кеча, $date';
  }

  @override
  String get todayLabel => 'Бугун';

  @override
  String get retryButton => 'Қайта уриниш';

  @override
  String get prayerTimeLabel => 'Намоз вақти';

  @override
  String get stopButton => 'Тўхтатиш';

  @override
  String get citySelectTitle => 'Шаҳарни танлаш';

  @override
  String get citySearchHint => 'Шаҳар қидириш';

  @override
  String get cityAutoDetect => 'Автоматик аниқлаш';

  @override
  String get cityAutoDetecting => 'Жойлашувингиз аниқланмоқда…';

  @override
  String get cityCurrentLocation => 'Жорий жойлашув';

  @override
  String get cityLocationServiceDisabled =>
      'Қурилма созламаларида геолокацияни ёқинг';

  @override
  String get cityLocationPermissionDenied =>
      'Геолокацияга рухсат берилмаган. Созламаларда рухсат беринг';

  @override
  String get cityLocationErrorGeneric => 'Жойлашувни аниқлаб бўлмади';

  @override
  String get cityOpenSettingsButton => 'Созламаларни очиш';

  @override
  String get cityOnlineResultsTitle => 'Интернетдан топилди';

  @override
  String get cityMoscow => 'Москва';

  @override
  String get cityKazan => 'Қозон';

  @override
  String get cityUfa => 'Уфа';

  @override
  String get cityGrozny => 'Грозний';

  @override
  String get cityMakhachkala => 'Махачқала';

  @override
  String get cityIstanbul => 'Истанбул';

  @override
  String get cityCairo => 'Қоҳира';

  @override
  String get cityJakarta => 'Жакарта';

  @override
  String get cityTashkent => 'Тошкент';

  @override
  String get cityAlmaty => 'Алмати';

  @override
  String get cityBaku => 'Боку';

  @override
  String get cityMecca => 'Макка';

  @override
  String get cityMedina => 'Мадина';

  @override
  String get cityMinsk => 'Минск';

  @override
  String get cityAstana => 'Остона';

  @override
  String get cityYerevan => 'Ереван';

  @override
  String get cityChisinau => 'Кишинёв';

  @override
  String get cityBishkek => 'Бишкек';

  @override
  String get cityDushanbe => 'Душанбе';

  @override
  String get cityAshgabat => 'Ашхобод';

  @override
  String get citySamarkand => 'Самарқанд';

  @override
  String get cityBukhara => 'Бухоро';

  @override
  String get cityNamangan => 'Наманган';

  @override
  String get cityAndijan => 'Андижон';

  @override
  String get countryRussia => 'Россия';

  @override
  String get countryTurkey => 'Туркия';

  @override
  String get countryEgypt => 'Миср';

  @override
  String get countryIndonesia => 'Индонезия';

  @override
  String get countryUzbekistan => 'Ўзбекистон';

  @override
  String get countryKazakhstan => 'Қозоғистон';

  @override
  String get countryAzerbaijan => 'Озарбайжон';

  @override
  String get countrySaudiArabia => 'Саудия Арабистони';

  @override
  String get countryBelarus => 'Беларусь';

  @override
  String get countryArmenia => 'Арманистон';

  @override
  String get countryMoldova => 'Молдова';

  @override
  String get countryKyrgyzstan => 'Қирғизистон';

  @override
  String get countryTajikistan => 'Тожикистон';

  @override
  String get countryTurkmenistan => 'Туркманистон';

  @override
  String get methodScreenTitle => 'Ҳисоблаш усули';

  @override
  String get methodUzbekistan => 'Ўзбекистон мусулмонлари идораси';

  @override
  String get methodKarachi => 'Ислом фанлари университети, Карачи';

  @override
  String get methodIsna => 'Шимолий Америка Ислом жамияти';

  @override
  String get methodMwl => 'Бутунжаҳон мусулмонлар лигаси';

  @override
  String get methodUmmAlQura => 'Умм ал-Қура университети, Макка';

  @override
  String get methodEgypt => 'Миср Бош бошқармаси';

  @override
  String get methodTurkey => 'Туркия Диний ишлар бошқармаси';

  @override
  String get languageScreenTitle => 'Тил';

  @override
  String get allahNamesTitle => 'Аллоҳнинг исмлари';

  @override
  String get allahNamesSubtitle => 'Асмаул Ҳусна';

  @override
  String get tabAll => 'Барчаси';

  @override
  String get tabFavorites => 'Танланганлар';

  @override
  String get nothingFound => 'Ҳеч нарса топилмади';

  @override
  String get favoritesEmpty =>
      'Танланганларга қўшилган исмлар шу ерда кўринади';

  @override
  String get namesSearchHint => 'Рақами, номи, маъноси бўйича қидириш';

  @override
  String get descriptionLabel => 'Таъриф';

  @override
  String get notificationsScreenTitle => 'Билдиришномалар';

  @override
  String get azanByPrayersKicker => 'Ҳар намоз учун билдиришнома';

  @override
  String get quietKicker => 'Жимлик';

  @override
  String get dontDisturbNight => 'Кечаси безовта қилмаслик';

  @override
  String logSheetTitle(String prayer) {
    return '$prayer қандай ўтди?';
  }

  @override
  String get logSheetSubtitle => 'Бу намозни қандай ўқиганингизни белгиланг';

  @override
  String get logSheetOnTime => 'Ўз вақтида ўқидим';

  @override
  String get logSheetLate => 'Кечикиб ўқидим';

  @override
  String get logSheetClear => 'Белгини олиб ташлаш';

  @override
  String get settingsScreenTitle => 'Созламалар';

  @override
  String get prayerSettingsTitle => 'Намоз вақти';

  @override
  String get systemSettingsTitle => 'Тизим созламалари';

  @override
  String get cityKicker => 'Шаҳар';

  @override
  String get madhabKicker => 'Мазҳаб (Аср ҳисоби)';

  @override
  String get madhabShafi => 'Шофиий';

  @override
  String get madhabHanafi => 'Ҳанафий';

  @override
  String get azanAndReminders => 'Билдиришномалар ва эслатмалар';

  @override
  String get themeKicker => 'Мавзу';

  @override
  String get themeLight => 'Ёруғ';

  @override
  String get themeDark => 'Қоронғи';

  @override
  String get themeSystem => 'Тизим';

  @override
  String get tahajjudKicker => 'Таҳажжуд намози';

  @override
  String get tahajjudEnableRow => 'Таҳажжуд намозини кўрсатиш';

  @override
  String get prayerTahajjud => 'Таҳажжуд';

  @override
  String get prayerFajr => 'Бомдод';

  @override
  String get prayerSunrise => 'Қуёш чиқиши';

  @override
  String get prayerZuhr => 'Пешин';

  @override
  String get prayerAsr => 'Аср';

  @override
  String get prayerMaghrib => 'Шом';

  @override
  String get prayerIsha => 'Хуфтон';

  @override
  String get weekdayShortMon => 'Ду';

  @override
  String get weekdayShortTue => 'Се';

  @override
  String get weekdayShortWed => 'Чо';

  @override
  String get weekdayShortThu => 'Па';

  @override
  String get weekdayShortFri => 'Жу';

  @override
  String get weekdayShortSat => 'Ша';

  @override
  String get weekdayShortSun => 'Як';

  @override
  String get weekdayFullMon => 'душанба';

  @override
  String get weekdayFullTue => 'сешанба';

  @override
  String get weekdayFullWed => 'чоршанба';

  @override
  String get weekdayFullThu => 'пайшанба';

  @override
  String get weekdayFullFri => 'жума';

  @override
  String get weekdayFullSat => 'шанба';

  @override
  String get weekdayFullSun => 'якшанба';

  @override
  String get month01 => 'январ';

  @override
  String get month02 => 'феврал';

  @override
  String get month03 => 'март';

  @override
  String get month04 => 'апрел';

  @override
  String get month05 => 'май';

  @override
  String get month06 => 'июн';

  @override
  String get month07 => 'июл';

  @override
  String get month08 => 'август';

  @override
  String get month09 => 'сентябр';

  @override
  String get month10 => 'октябр';

  @override
  String get month11 => 'ноябр';

  @override
  String get month12 => 'декабр';

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return '$hours соат $minutes дақиқадан сўнг';
  }

  @override
  String countdownHoursOnly(int hours) {
    return '$hours соатдан сўнг';
  }

  @override
  String countdownMinutesOnly(int minutes) {
    return '$minutes дақиқадан сўнг';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer намози вақти бўлди';
  }

  @override
  String get notifBody => 'Намоз ўқиш вақти';

  @override
  String get notifMarkDoneAction => 'Бажардим';

  @override
  String get errorTimeout =>
      'Кутиш вақти тугади. Интернет алоқасини текширинг.';

  @override
  String get errorNoConnection => 'Интернет алоқаси йўқ.';

  @override
  String get errorServiceUnavailable =>
      'Намоз вақтлари хизмати вақтинча ишламаяпти.';

  @override
  String get errorParseFailed => 'Хизмат жавобини қайта ишлаб бўлмади.';

  @override
  String get errorFetchFailed => 'Намоз вақтларини олиб бўлмади.';

  @override
  String get genericLoadError => 'Намоз вақтларини юклаб бўлмади.';

  @override
  String get errorOfflineSettingsChange =>
      'Ушбу созламаларни ўзгартириш учун интернет уланиши керак.';

  @override
  String get calendarScreenTitle => 'Намоз тақвими';

  @override
  String get legendOnTime => 'Ўз вақтида';

  @override
  String get legendQada => 'Кечикиб';

  @override
  String get legendMissed => 'Ўтказиб юборилган';

  @override
  String get notifEveningReminderTitle => 'Намозларингизни белгилашни унутманг';

  @override
  String get notifEveningReminderBody =>
      'Иловага кириб, бугунги намозларингиз қандай ўтганини белгиланг';

  @override
  String notifPrayerEndingTitle(String prayer) {
    return '$prayer вақти тугаяпти';
  }

  @override
  String notifPrayerEndingBody(int minutes) {
    return '$minutes дақиқа қолди, намоз ҳали ўқилган деб белгиланмаган';
  }

  @override
  String get widgetMarkedLabel => 'Белгиланди';

  @override
  String get widgetNoDataLabel => 'Иловани очинг';
}

/// The translations for Uzbek, using the Latin script (`uz_Latn`).
class AppLocalizationsUzLatn extends AppLocalizationsUz {
  AppLocalizationsUzLatn() : super('uz_Latn');

  @override
  String get navPrayer => 'Namoz';

  @override
  String get navMore => 'Yana';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get nextPrayerLabel => 'Keyingi namoz';

  @override
  String nextPrayerTomorrowLabel(String date) {
    return 'Ertaga, $date';
  }

  @override
  String yesterdayCurrentLabel(String date) {
    return 'Kecha, $date';
  }

  @override
  String get todayLabel => 'Bugun';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get prayerTimeLabel => 'Namoz vaqti';

  @override
  String get stopButton => 'To\'xtatish';

  @override
  String get citySelectTitle => 'Shaharni tanlash';

  @override
  String get citySearchHint => 'Shahar qidirish';

  @override
  String get cityAutoDetect => 'Avtomatik aniqlash';

  @override
  String get cityAutoDetecting => 'Joylashuvingiz aniqlanmoqda…';

  @override
  String get cityCurrentLocation => 'Joriy joylashuv';

  @override
  String get cityLocationServiceDisabled =>
      'Qurilma sozlamalarida geolokatsiyani yoqing';

  @override
  String get cityLocationPermissionDenied =>
      'Geolokatsiyaga ruxsat berilmagan. Sozlamalarda ruxsat bering';

  @override
  String get cityLocationErrorGeneric => 'Joylashuvni aniqlab bo\'lmadi';

  @override
  String get cityOpenSettingsButton => 'Sozlamalarni ochish';

  @override
  String get cityOnlineResultsTitle => 'Internetdan topildi';

  @override
  String get cityMoscow => 'Moskva';

  @override
  String get cityKazan => 'Qozon';

  @override
  String get cityUfa => 'Ufa';

  @override
  String get cityGrozny => 'Grozniy';

  @override
  String get cityMakhachkala => 'Maxachqala';

  @override
  String get cityIstanbul => 'Istanbul';

  @override
  String get cityCairo => 'Qohira';

  @override
  String get cityJakarta => 'Jakarta';

  @override
  String get cityTashkent => 'Toshkent';

  @override
  String get cityAlmaty => 'Almati';

  @override
  String get cityBaku => 'Boku';

  @override
  String get cityMecca => 'Makka';

  @override
  String get cityMedina => 'Madina';

  @override
  String get cityMinsk => 'Minsk';

  @override
  String get cityAstana => 'Ostona';

  @override
  String get cityYerevan => 'Yerevan';

  @override
  String get cityChisinau => 'Kishinyov';

  @override
  String get cityBishkek => 'Bishkek';

  @override
  String get cityDushanbe => 'Dushanbe';

  @override
  String get cityAshgabat => 'Ashxobod';

  @override
  String get citySamarkand => 'Samarqand';

  @override
  String get cityBukhara => 'Buxoro';

  @override
  String get cityNamangan => 'Namangan';

  @override
  String get cityAndijan => 'Andijon';

  @override
  String get countryRussia => 'Rossiya';

  @override
  String get countryTurkey => 'Turkiya';

  @override
  String get countryEgypt => 'Misr';

  @override
  String get countryIndonesia => 'Indoneziya';

  @override
  String get countryUzbekistan => 'O\'zbekiston';

  @override
  String get countryKazakhstan => 'Qozog\'iston';

  @override
  String get countryAzerbaijan => 'Ozarbayjon';

  @override
  String get countrySaudiArabia => 'Saudiya Arabistoni';

  @override
  String get countryBelarus => 'Belarus';

  @override
  String get countryArmenia => 'Armaniston';

  @override
  String get countryMoldova => 'Moldova';

  @override
  String get countryKyrgyzstan => 'Qirg\'iziston';

  @override
  String get countryTajikistan => 'Tojikiston';

  @override
  String get countryTurkmenistan => 'Turkmaniston';

  @override
  String get methodScreenTitle => 'Hisoblash usuli';

  @override
  String get methodUzbekistan => 'O\'zbekiston musulmonlari idorasi';

  @override
  String get methodKarachi => 'Islom fanlari universiteti, Karachi';

  @override
  String get methodIsna => 'Shimoliy Amerika Islom jamiyati';

  @override
  String get methodMwl => 'Butunjahon musulmonlar ligasi';

  @override
  String get methodUmmAlQura => 'Umm al-Qura universiteti, Makka';

  @override
  String get methodEgypt => 'Misr Bosh boshqarmasi';

  @override
  String get methodTurkey => 'Turkiya Diniy ishlar boshqarmasi';

  @override
  String get languageScreenTitle => 'Til';

  @override
  String get allahNamesTitle => 'Allohning ismlari';

  @override
  String get allahNamesSubtitle => 'Asmaul Husna';

  @override
  String get tabAll => 'Barchasi';

  @override
  String get tabFavorites => 'Tanlanganlar';

  @override
  String get nothingFound => 'Hech narsa topilmadi';

  @override
  String get favoritesEmpty =>
      'Tanlanganlarga qo\'shilgan ismlar shu yerda ko\'rinadi';

  @override
  String get namesSearchHint => 'Raqami, nomi, ma\'nosi bo\'yicha qidirish';

  @override
  String get descriptionLabel => 'Ta\'rif';

  @override
  String get notificationsScreenTitle => 'Bildirishnomalar';

  @override
  String get azanByPrayersKicker => 'Har namoz uchun bildirishnoma';

  @override
  String get quietKicker => 'Jimlik';

  @override
  String get dontDisturbNight => 'Kechasi bezovta qilmaslik';

  @override
  String logSheetTitle(String prayer) {
    return '$prayer qanday o\'tdi?';
  }

  @override
  String get logSheetSubtitle => 'Bu namozni qanday o\'qiganingizni belgilang';

  @override
  String get logSheetOnTime => 'O\'z vaqtida o\'qidim';

  @override
  String get logSheetLate => 'Kechikib o\'qidim';

  @override
  String get logSheetClear => 'Belgini olib tashlash';

  @override
  String get settingsScreenTitle => 'Sozlamalar';

  @override
  String get prayerSettingsTitle => 'Namoz vaqti';

  @override
  String get systemSettingsTitle => 'Tizim sozlamalari';

  @override
  String get cityKicker => 'Shahar';

  @override
  String get madhabKicker => 'Mazhab (Asr hisobi)';

  @override
  String get madhabShafi => 'Shofi\'iy';

  @override
  String get madhabHanafi => 'Hanafiy';

  @override
  String get azanAndReminders => 'Bildirishnomalar va eslatmalar';

  @override
  String get themeKicker => 'Mavzu';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get themeSystem => 'Tizim';

  @override
  String get tahajjudKicker => 'Tahajjud namozi';

  @override
  String get tahajjudEnableRow => 'Tahajjud namozini ko\'rsatish';

  @override
  String get prayerTahajjud => 'Tahajjud';

  @override
  String get prayerFajr => 'Bomdod';

  @override
  String get prayerSunrise => 'Quyosh chiqishi';

  @override
  String get prayerZuhr => 'Peshin';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Shom';

  @override
  String get prayerIsha => 'Xufton';

  @override
  String get weekdayShortMon => 'Du';

  @override
  String get weekdayShortTue => 'Se';

  @override
  String get weekdayShortWed => 'Cho';

  @override
  String get weekdayShortThu => 'Pa';

  @override
  String get weekdayShortFri => 'Ju';

  @override
  String get weekdayShortSat => 'Sha';

  @override
  String get weekdayShortSun => 'Yak';

  @override
  String get weekdayFullMon => 'dushanba';

  @override
  String get weekdayFullTue => 'seshanba';

  @override
  String get weekdayFullWed => 'chorshanba';

  @override
  String get weekdayFullThu => 'payshanba';

  @override
  String get weekdayFullFri => 'juma';

  @override
  String get weekdayFullSat => 'shanba';

  @override
  String get weekdayFullSun => 'yakshanba';

  @override
  String get month01 => 'yanvar';

  @override
  String get month02 => 'fevral';

  @override
  String get month03 => 'mart';

  @override
  String get month04 => 'aprel';

  @override
  String get month05 => 'may';

  @override
  String get month06 => 'iyun';

  @override
  String get month07 => 'iyul';

  @override
  String get month08 => 'avgust';

  @override
  String get month09 => 'sentabr';

  @override
  String get month10 => 'oktabr';

  @override
  String get month11 => 'noyabr';

  @override
  String get month12 => 'dekabr';

  @override
  String countdownHoursMinutes(int hours, int minutes) {
    return '$hours soat $minutes daqiqadan so\'ng';
  }

  @override
  String countdownHoursOnly(int hours) {
    return '$hours soatdan so\'ng';
  }

  @override
  String countdownMinutesOnly(int minutes) {
    return '$minutes daqiqadan so\'ng';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer namozi vaqti bo\'ldi';
  }

  @override
  String get notifBody => 'Namoz o\'qish vaqti';

  @override
  String get notifMarkDoneAction => 'Bajardim';

  @override
  String get errorTimeout =>
      'Kutish vaqti tugadi. Internet aloqasini tekshiring.';

  @override
  String get errorNoConnection => 'Internet aloqasi yo\'q.';

  @override
  String get errorServiceUnavailable =>
      'Namoz vaqtlari xizmati vaqtincha ishlamayapti.';

  @override
  String get errorParseFailed => 'Xizmat javobini qayta ishlab bo\'lmadi.';

  @override
  String get errorFetchFailed => 'Namoz vaqtlarini olib bo\'lmadi.';

  @override
  String get genericLoadError => 'Namoz vaqtlarini yuklab bo\'lmadi.';

  @override
  String get errorOfflineSettingsChange =>
      'Ushbu sozlamalarni o\'zgartirish uchun internet ulanishi kerak.';

  @override
  String get calendarScreenTitle => 'Namoz taqvimi';

  @override
  String get legendOnTime => 'O\'z vaqtida';

  @override
  String get legendQada => 'Kechikib';

  @override
  String get legendMissed => 'O\'tkazib yuborilgan';

  @override
  String get notifEveningReminderTitle =>
      'Namozlaringizni belgilashni unutmang';

  @override
  String get notifEveningReminderBody =>
      'Ilovaga kirib, bugungi namozlaringiz qanday o\'tganini belgilang';

  @override
  String notifPrayerEndingTitle(String prayer) {
    return '$prayer vaqti tugayapti';
  }

  @override
  String notifPrayerEndingBody(int minutes) {
    return '$minutes daqiqa qoldi, namoz hali o\'qilgan deb belgilanmagan';
  }

  @override
  String get widgetMarkedLabel => 'Belgilandi';

  @override
  String get widgetNoDataLabel => 'Ilovani oching';
}
