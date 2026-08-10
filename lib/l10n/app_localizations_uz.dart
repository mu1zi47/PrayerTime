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
  String get todayLabel => 'Bugun';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get prayerTimeLabel => 'Namoz vaqti';

  @override
  String get stopButton => 'To\'xtatish';

  @override
  String get azanScreenTitle => 'Azon';

  @override
  String get azanPlaceholderNote =>
      'Hozircha barcha qorilar uchun bitta vaqtinchalik signal o\'ynaladi — haqiqiy yozuvlar keyinroq qo\'shiladi.';

  @override
  String get citySelectTitle => 'Shaharni tanlash';

  @override
  String get citySearchHint => 'Shahar qidirish';

  @override
  String get cityAutoDetect => 'Avtomatik aniqlash';

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
  String get myPrayersTitle => 'Mening namozlarim';

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
  String get azanByPrayersKicker => 'Har namoz uchun azon';

  @override
  String get soundKicker => 'Tovush';

  @override
  String azanSoundRow(String reciter) {
    return 'Azon — $reciter';
  }

  @override
  String get reciterAbdulbasit => 'Abdulbosit Abdussamad';

  @override
  String get reciterAknazar => 'Aqnazar Maratuli';

  @override
  String get reciterAliAhmedMulla => 'Ali Ahmad Mulla';

  @override
  String get reciterAhmedAlNufais => 'Ahmad an-Nufays';

  @override
  String get reciterBaubek => 'Baubek Berdigaliuli';

  @override
  String get reciterMustafaIsmail => 'Mustafo Ismoil';

  @override
  String get reciterMishari => 'Mishari Rashid al-Afasi';

  @override
  String get reciterMustafaOzcan => 'Mustafo O\'zjan Guneshdog\'di';

  @override
  String get reciterMansurZahrani => 'Mansur az-Zahroniy';

  @override
  String get reciterNasirQatami => 'Nosir al-Qatomiy';

  @override
  String get reciterRaadKurdi => 'Raad Muhammad al-Kurdiy';

  @override
  String get reciterSaidmuhammed => 'Saidmuhammad Nigmat';

  @override
  String get reciterNoteTakbirShort => 'takbir, qisqa versiya';

  @override
  String get reciterNoteStudioRecording => 'studiya yozuvi';

  @override
  String get quietKicker => 'Jimlik';

  @override
  String get dontDisturbNight => 'Kechasi bezovta qilmaslik';

  @override
  String get nowBarScreenTitle => 'Now Bar';

  @override
  String get nowBarAvailability =>
      'Faqat One UI 7 va undan yuqori Samsung qurilmalarida mavjud';

  @override
  String get nowBarShowCurrent => 'Joriy namozni ko\'rsatish';

  @override
  String get nowBarShowNext => 'Keyingi namozni ko\'rsatish';

  @override
  String get nowBarAllowPermission => 'Now Bar\'da ko\'rsatishga ruxsat berish';

  @override
  String get myPrayersSubtitle => 'O\'qilgan namozlarni belgilang';

  @override
  String prayerLogDone(int done, int total) {
    return '$total tadan $done tasi bajarildi';
  }

  @override
  String prayerLogLateSuffix(int count) {
    return ' · Vaqtida emas: $count';
  }

  @override
  String get notYetDue => 'Hali vaqti kelmagan';

  @override
  String get statusOnTime => 'O\'z vaqtida';

  @override
  String get statusLate => 'Vaqtida emas';

  @override
  String get settingsScreenTitle => 'Sozlamalar';

  @override
  String get cityKicker => 'Shahar';

  @override
  String get madhabKicker => 'Mazhab (Asr hisobi)';

  @override
  String get madhabShafi => 'Shofi\'iy';

  @override
  String get madhabHanafi => 'Hanafiy';

  @override
  String get azanAndReminders => 'Azon va eslatmalar';

  @override
  String get nowBarSettingsRow => 'Joriy va keyingi namoz';

  @override
  String get themeKicker => 'Mavzu';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get themeSystem => 'Tizim';

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
  String notifAzanTitle(String prayer) {
    return 'Azon — $prayer';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer namozi vaqti bo\'ldi';
  }

  @override
  String get notifBody => 'Namoz o\'qish vaqti';

  @override
  String get nowBarNotificationTitle => 'Namoz';

  @override
  String nowBarCurrentLine(String prayer) {
    return 'Hozir: $prayer';
  }

  @override
  String nowBarNextLine(String prayer, String time) {
    return 'Keyin: $prayer, $time';
  }

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
  String get todayLabel => 'Бугун';

  @override
  String get retryButton => 'Қайта уриниш';

  @override
  String get prayerTimeLabel => 'Намоз вақти';

  @override
  String get stopButton => 'Тўхтатиш';

  @override
  String get azanScreenTitle => 'Азон';

  @override
  String get azanPlaceholderNote =>
      'Ҳозирча барча қорилар учун битта вақтинчалик сигнал ўйналади — ҳақиқий ёзувлар кейинроқ қўшилади.';

  @override
  String get citySelectTitle => 'Шаҳарни танлаш';

  @override
  String get citySearchHint => 'Шаҳар қидириш';

  @override
  String get cityAutoDetect => 'Автоматик аниқлаш';

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
  String get myPrayersTitle => 'Менинг намозларим';

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
  String get azanByPrayersKicker => 'Ҳар намоз учун азон';

  @override
  String get soundKicker => 'Товуш';

  @override
  String azanSoundRow(String reciter) {
    return 'Азон — $reciter';
  }

  @override
  String get reciterAbdulbasit => 'Абдулбосит Абдуссамад';

  @override
  String get reciterAknazar => 'Ақназар Маратули';

  @override
  String get reciterAliAhmedMulla => 'Али Аҳмад Мулла';

  @override
  String get reciterAhmedAlNufais => 'Аҳмад ан-Нуфайс';

  @override
  String get reciterBaubek => 'Баубек Бердигалиули';

  @override
  String get reciterMustafaIsmail => 'Мустафо Исмоил';

  @override
  String get reciterMishari => 'Мишари Рашид ал-Афаси';

  @override
  String get reciterMustafaOzcan => 'Мустафо Ўзжан Гунешдоғди';

  @override
  String get reciterMansurZahrani => 'Мансур аз-Заҳроний';

  @override
  String get reciterNasirQatami => 'Носир ал-Қатомий';

  @override
  String get reciterRaadKurdi => 'Раад Муҳаммад ал-Курдий';

  @override
  String get reciterSaidmuhammed => 'Саидмуҳаммад Нигмат';

  @override
  String get reciterNoteTakbirShort => 'такбир, қисқа версия';

  @override
  String get reciterNoteStudioRecording => 'студия ёзуви';

  @override
  String get quietKicker => 'Жимлик';

  @override
  String get dontDisturbNight => 'Кечаси безовта қилмаслик';

  @override
  String get nowBarScreenTitle => 'Now Bar';

  @override
  String get nowBarAvailability =>
      'Фақат One UI 7 ва ундан юқори Samsung қурилмаларида мавжуд';

  @override
  String get nowBarShowCurrent => 'Жорий намозни кўрсатиш';

  @override
  String get nowBarShowNext => 'Кейинги намозни кўрсатиш';

  @override
  String get nowBarAllowPermission => 'Now Bar\'да кўрсатишга рухсат бериш';

  @override
  String get myPrayersSubtitle => 'Ўқилган намозларни белгиланг';

  @override
  String prayerLogDone(int done, int total) {
    return '$total тадан $done таси бажарилди';
  }

  @override
  String prayerLogLateSuffix(int count) {
    return ' · Вақтида эмас: $count';
  }

  @override
  String get notYetDue => 'Ҳали вақти келмаган';

  @override
  String get statusOnTime => 'Ўз вақтида';

  @override
  String get statusLate => 'Вақтида эмас';

  @override
  String get settingsScreenTitle => 'Созламалар';

  @override
  String get cityKicker => 'Шаҳар';

  @override
  String get madhabKicker => 'Мазҳаб (Аср ҳисоби)';

  @override
  String get madhabShafi => 'Шофиий';

  @override
  String get madhabHanafi => 'Ҳанафий';

  @override
  String get azanAndReminders => 'Азон ва эслатмалар';

  @override
  String get nowBarSettingsRow => 'Жорий ва кейинги намоз';

  @override
  String get themeKicker => 'Мавзу';

  @override
  String get themeLight => 'Ёруғ';

  @override
  String get themeDark => 'Қоронғи';

  @override
  String get themeSystem => 'Тизим';

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
  String notifAzanTitle(String prayer) {
    return 'Азон — $prayer';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer намози вақти бўлди';
  }

  @override
  String get notifBody => 'Намоз ўқиш вақти';

  @override
  String get nowBarNotificationTitle => 'Намоз';

  @override
  String nowBarCurrentLine(String prayer) {
    return 'Ҳозир: $prayer';
  }

  @override
  String nowBarNextLine(String prayer, String time) {
    return 'Кейин: $prayer, $time';
  }

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
  String get todayLabel => 'Bugun';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get prayerTimeLabel => 'Namoz vaqti';

  @override
  String get stopButton => 'To\'xtatish';

  @override
  String get azanScreenTitle => 'Azon';

  @override
  String get azanPlaceholderNote =>
      'Hozircha barcha qorilar uchun bitta vaqtinchalik signal o\'ynaladi — haqiqiy yozuvlar keyinroq qo\'shiladi.';

  @override
  String get citySelectTitle => 'Shaharni tanlash';

  @override
  String get citySearchHint => 'Shahar qidirish';

  @override
  String get cityAutoDetect => 'Avtomatik aniqlash';

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
  String get myPrayersTitle => 'Mening namozlarim';

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
  String get azanByPrayersKicker => 'Har namoz uchun azon';

  @override
  String get soundKicker => 'Tovush';

  @override
  String azanSoundRow(String reciter) {
    return 'Azon — $reciter';
  }

  @override
  String get reciterAbdulbasit => 'Abdulbosit Abdussamad';

  @override
  String get reciterAknazar => 'Aqnazar Maratuli';

  @override
  String get reciterAliAhmedMulla => 'Ali Ahmad Mulla';

  @override
  String get reciterAhmedAlNufais => 'Ahmad an-Nufays';

  @override
  String get reciterBaubek => 'Baubek Berdigaliuli';

  @override
  String get reciterMustafaIsmail => 'Mustafo Ismoil';

  @override
  String get reciterMishari => 'Mishari Rashid al-Afasi';

  @override
  String get reciterMustafaOzcan => 'Mustafo O\'zjan Guneshdog\'di';

  @override
  String get reciterMansurZahrani => 'Mansur az-Zahroniy';

  @override
  String get reciterNasirQatami => 'Nosir al-Qatomiy';

  @override
  String get reciterRaadKurdi => 'Raad Muhammad al-Kurdiy';

  @override
  String get reciterSaidmuhammed => 'Saidmuhammad Nigmat';

  @override
  String get reciterNoteTakbirShort => 'takbir, qisqa versiya';

  @override
  String get reciterNoteStudioRecording => 'studiya yozuvi';

  @override
  String get quietKicker => 'Jimlik';

  @override
  String get dontDisturbNight => 'Kechasi bezovta qilmaslik';

  @override
  String get nowBarScreenTitle => 'Now Bar';

  @override
  String get nowBarAvailability =>
      'Faqat One UI 7 va undan yuqori Samsung qurilmalarida mavjud';

  @override
  String get nowBarShowCurrent => 'Joriy namozni ko\'rsatish';

  @override
  String get nowBarShowNext => 'Keyingi namozni ko\'rsatish';

  @override
  String get nowBarAllowPermission => 'Now Bar\'da ko\'rsatishga ruxsat berish';

  @override
  String get myPrayersSubtitle => 'O\'qilgan namozlarni belgilang';

  @override
  String prayerLogDone(int done, int total) {
    return '$total tadan $done tasi bajarildi';
  }

  @override
  String prayerLogLateSuffix(int count) {
    return ' · Vaqtida emas: $count';
  }

  @override
  String get notYetDue => 'Hali vaqti kelmagan';

  @override
  String get statusOnTime => 'O\'z vaqtida';

  @override
  String get statusLate => 'Vaqtida emas';

  @override
  String get settingsScreenTitle => 'Sozlamalar';

  @override
  String get cityKicker => 'Shahar';

  @override
  String get madhabKicker => 'Mazhab (Asr hisobi)';

  @override
  String get madhabShafi => 'Shofi\'iy';

  @override
  String get madhabHanafi => 'Hanafiy';

  @override
  String get azanAndReminders => 'Azon va eslatmalar';

  @override
  String get nowBarSettingsRow => 'Joriy va keyingi namoz';

  @override
  String get themeKicker => 'Mavzu';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'i';

  @override
  String get themeSystem => 'Tizim';

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
  String notifAzanTitle(String prayer) {
    return 'Azon — $prayer';
  }

  @override
  String notifPlainTitle(String prayer) {
    return '$prayer namozi vaqti bo\'ldi';
  }

  @override
  String get notifBody => 'Namoz o\'qish vaqti';

  @override
  String get nowBarNotificationTitle => 'Namoz';

  @override
  String nowBarCurrentLine(String prayer) {
    return 'Hozir: $prayer';
  }

  @override
  String nowBarNextLine(String prayer, String time) {
    return 'Keyin: $prayer, $time';
  }

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
}
