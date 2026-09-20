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
  String get widgetMarkedLabel => 'Bajarildi';

  @override
  String get widgetNoDataLabel => 'Ilovani oching';

  @override
  String get nowBarTitle => 'Now Bar';

  @override
  String get persistentNotifTitle => 'Doimiy bildirishnoma';

  @override
  String get nowBarDescription => 'Joriy namoz Now Bar\'da ko\'rsatiladi.';

  @override
  String get persistentNotifDescription =>
      'Joriy namoz bildirishnomalarda ko\'rsatiladi.';

  @override
  String get nowBarSwitchLabel => 'Now Bar\'da ko\'rsatish';

  @override
  String get persistentNotifSwitchLabel => 'Bildirishnomani ko\'rsatish';

  @override
  String get infoButtonLabel => 'Batafsil';

  @override
  String get nowBarOn => 'Yoqilgan';

  @override
  String get nowBarOff => 'O\'chirilgan';

  @override
  String get nowBarNotificationsOff =>
      'Telefon sozlamalarida ilova bildirishnomalari o\'chirilgan, shuning uchun u ko\'rinmaydi.';

  @override
  String get nowBarOpenSettings => 'Telefon sozlamalarini ochish';

  @override
  String get nowBarOpenAction => 'Ochish';

  @override
  String get nowBarEndsIn => 'Tugashiga';

  @override
  String get nowBarStartsIn => 'Boshlanishiga';

  @override
  String get nowBarChannelName => 'Joriy namoz';

  @override
  String get nowBarScheduleLabel => 'Barcha namozlarni ko\'rsatish';

  @override
  String get nowBarScheduleDescription =>
      'Barcha namozlar Now Bar\'da ko\'rsatiladi.';

  @override
  String get nowBarScheduleDescriptionPlain =>
      'Barcha namozlar bildirishnomalarda ko\'rsatiladi.';

  @override
  String get nowBarDevTitle => 'Bu telefonda Now Bar hali o\'chiq';

  @override
  String get nowBarDevBody =>
      'Samsung boshqa ilovalarni Now Bar\'ga faqat «Ishlab chiqaruvchi opsiyalari» ichidagi kalit yoqilgandan keyin chiqaradi. Unga qadar namoz oddiy bildirishnoma bo\'lib ko\'rinadi.';

  @override
  String get nowBarDevStepAbout =>
      '«Sozlamalar» → «Telefon haqida» → «Dastur haqida ma’lumot» bo\'limini oching.';

  @override
  String get nowBarDevStepBuildNumber =>
      '«Reliz raqami» ustiga ketma-ket 7 marta bosing va telefon so\'rasa, PIN-kodni kiriting. «Ishlab chiqaruvchi opsiyalari» paydo bo\'ladi.';

  @override
  String get nowBarDevStepDeveloperOptions =>
      '«Sozlamalar»ga qayting va ro\'yxatning eng pastidagi «Ishlab chiqaruvchi opsiyalari» bo\'limini oching.';

  @override
  String get nowBarDevStepSwitch =>
      '«Hamma ilv. u-n jonli bildir-lar» bandini toping va yoqing.';

  @override
  String get nowBarDevOpenAbout => '«Telefon haqida»ni ochish';

  @override
  String get nowBarDevOpenDeveloper =>
      '«Ishlab chiqaruvchi opsiyalari»ni ochish';

  @override
  String onboardingStepLabel(int current, int total) {
    return '$current-qadam, jami $total';
  }

  @override
  String get onboardingNext => 'Keyingisi';

  @override
  String get onboardingBack => 'Orqaga';

  @override
  String get onboardingFinish => 'Tayyor';

  @override
  String get onboardingLanguageTitle => 'Ilova tili';

  @override
  String get onboardingLanguageBody =>
      'Namoz nomlari, maslahatlar va bildirishnomalar shu tilda bo\'ladi. Istalgan vaqtda sozlamalardan o\'zgartirasiz.';

  @override
  String get onboardingThemeTitle => 'Ko\'rinishi';

  @override
  String get onboardingThemeBody =>
      'Yorug\', qorong\'i yoki telefondagidek. Bosh ekrandagi vidjet ham shu tanlovga ergashadi.';

  @override
  String get onboardingCityTitle => 'Shahringiz';

  @override
  String get onboardingCityBody =>
      'Namoz vaqtlari koordinatalarga bog\'liq, shuning uchun shahar eng muhim sozlama. Uni avtomatik aniqlang yoki o\'zingiz tanlang.';

  @override
  String get onboardingCityDetect => 'Avtomatik aniqlash';

  @override
  String get onboardingCityManual => 'O\'zim tanlayman';

  @override
  String get onboardingCitySelected => 'Tanlangan shahar';

  @override
  String get onboardingMethodTitle => 'Hisoblash usuli';

  @override
  String get onboardingMethodBody =>
      'Tashkilotlar bomdod va xufton uchun quyoshning turli burchaklaridan foydalanadi, shuning uchun vaqtlar bir necha daqiqaga farq qiladi. Yashaydigan joyingizda qabul qilinganini tanlang.';

  @override
  String get onboardingMadhabTitle => 'Mazhab';

  @override
  String get onboardingMadhabBody =>
      'Bu faqat asr vaqtiga ta\'sir qiladi: hanafiylarda u shofiylarnikidan kechroq kiradi.';

  @override
  String get onboardingNotifTitle => 'Bildirishnomalar';

  @override
  String get onboardingNotifBody =>
      'Ilova har bir namoz kirganini bildiradi va agar namoz o\'qildi deb belgilanmagan bo\'lsa, vaqti tugashiga 30 daqiqa qolganda yana eslatadi.';

  @override
  String get notifModeSound => 'Ovoz bilan';

  @override
  String get notifModeSilent => 'Ovozsiz';

  @override
  String get notifModeOff => 'O\'chirilgan';

  @override
  String get calendarNotMarked => 'Belgilanmagan';

  @override
  String get calendarDayPanelKicker => 'Namozlarni belgilang';

  @override
  String get namesNoticeTitle => 'Hozircha faqat o\'zbekcha';

  @override
  String get namesNoticeBody =>
      'Alloh ismlari va ularning sharhi hozircha faqat o\'zbek (kirill) tilida mavjud. Boshqa tillarga tarjimalari keyingi yangilanishlarda qo\'shiladi.';

  @override
  String get namesNoticeButton => 'Tushunarli';

  @override
  String get feedbackKicker => 'Aloqa';

  @override
  String get feedbackEmail => 'Pochtaga yozish';

  @override
  String get feedbackTelegram => 'Telegramga yozish';

  @override
  String get feedbackCopied => 'Nusxalandi';

  @override
  String appVersionLabel(String version) {
    return 'Versiya $version';
  }

  @override
  String get namesNoticeDisclaimer =>
      'Yozilishi va sharhlarida xatolar bo\'lishi mumkin. Xatoni sezsangiz, sozlamalardagi «Aloqa» bo\'limi orqali yozing.';

  @override
  String get namesDisclaimerTitle => 'E\'tibor bering';
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
  String get widgetMarkedLabel => 'Бажарилди';

  @override
  String get widgetNoDataLabel => 'Иловани очинг';

  @override
  String get nowBarTitle => 'Now Bar';

  @override
  String get persistentNotifTitle => 'Доимий билдиришнома';

  @override
  String get nowBarDescription => 'Жорий намоз Now Bar\'да кўрсатилади.';

  @override
  String get persistentNotifDescription =>
      'Жорий намоз билдиришномаларда кўрсатилади.';

  @override
  String get nowBarSwitchLabel => 'Now Bar\'да кўрсатиш';

  @override
  String get persistentNotifSwitchLabel => 'Билдиришномани кўрсатиш';

  @override
  String get infoButtonLabel => 'Батафсил';

  @override
  String get nowBarOn => 'Ёқилган';

  @override
  String get nowBarOff => 'Ўчирилган';

  @override
  String get nowBarNotificationsOff =>
      'Телефон созламаларида илова билдиришномалари ўчирилган, шунинг учун у кўринмайди.';

  @override
  String get nowBarOpenSettings => 'Телефон созламаларини очиш';

  @override
  String get nowBarOpenAction => 'Очиш';

  @override
  String get nowBarEndsIn => 'Тугашига';

  @override
  String get nowBarStartsIn => 'Бошланишига';

  @override
  String get nowBarChannelName => 'Жорий намоз';

  @override
  String get nowBarScheduleLabel => 'Барча намозларни кўрсатиш';

  @override
  String get nowBarScheduleDescription =>
      'Барча намозлар Now Bar\'да кўрсатилади.';

  @override
  String get nowBarScheduleDescriptionPlain =>
      'Барча намозлар билдиришномаларда кўрсатилади.';

  @override
  String get nowBarDevTitle => 'Бу телефонда Now Bar ҳали ўчиқ';

  @override
  String get nowBarDevBody =>
      'Samsung бошқа иловаларни Now Bar\'га фақат «Ishlab chiqaruvchi opsiyalari» ичидаги калит ёқилгандан кейин чиқаради. Унга қадар намоз оддий билдиришнома бўлиб кўринади.';

  @override
  String get nowBarDevStepAbout =>
      '«Sozlamalar» → «Telefon haqida» → «Dastur haqida ma’lumot» бўлимини очинг.';

  @override
  String get nowBarDevStepBuildNumber =>
      '«Reliz raqami» устига кетма-кет 7 марта босинг ва телефон сўраса, PIN-кодни киритинг. «Ishlab chiqaruvchi opsiyalari» пайдо бўлади.';

  @override
  String get nowBarDevStepDeveloperOptions =>
      '«Sozlamalar»га қайтинг ва рўйхатнинг энг пастидаги «Ishlab chiqaruvchi opsiyalari» бўлимини очинг.';

  @override
  String get nowBarDevStepSwitch =>
      '«Hamma ilv. u-n jonli bildir-lar» бандини топинг ва ёқинг.';

  @override
  String get nowBarDevOpenAbout => '«Telefon haqida»ни очиш';

  @override
  String get nowBarDevOpenDeveloper => '«Ishlab chiqaruvchi opsiyalari»ни очиш';

  @override
  String onboardingStepLabel(int current, int total) {
    return '$current-қадам, жами $total';
  }

  @override
  String get onboardingNext => 'Кейингиси';

  @override
  String get onboardingBack => 'Орқага';

  @override
  String get onboardingFinish => 'Тайёр';

  @override
  String get onboardingLanguageTitle => 'Илова тили';

  @override
  String get onboardingLanguageBody =>
      'Намоз номлари, маслаҳатлар ва билдиришномалар шу тилда бўлади. Исталган вақтда созламалардан ўзгартирасиз.';

  @override
  String get onboardingThemeTitle => 'Кўриниши';

  @override
  String get onboardingThemeBody =>
      'Ёруғ, қоронғи ёки телефондагидек. Бош экрандаги виджет ҳам шу танловга эргашади.';

  @override
  String get onboardingCityTitle => 'Шаҳрингиз';

  @override
  String get onboardingCityBody =>
      'Намоз вақтлари координаталарга боғлиқ, шунинг учун шаҳар энг муҳим созлама. Уни автоматик аниқланг ёки ўзингиз танланг.';

  @override
  String get onboardingCityDetect => 'Автоматик аниқлаш';

  @override
  String get onboardingCityManual => 'Ўзим танлайман';

  @override
  String get onboardingCitySelected => 'Танланган шаҳар';

  @override
  String get onboardingMethodTitle => 'Ҳисоблаш усули';

  @override
  String get onboardingMethodBody =>
      'Ташкилотлар бомдод ва хуфтон учун қуёшнинг турли бурчакларидан фойдаланади, шунинг учун вақтлар бир неча дақиқага фарқ қилади. Яшайдиган жойингизда қабул қилинганини танланг.';

  @override
  String get onboardingMadhabTitle => 'Мазҳаб';

  @override
  String get onboardingMadhabBody =>
      'Бу фақат аср вақтига таъсир қилади: ҳанафийларда у шофийларникидан кечроқ киради.';

  @override
  String get onboardingNotifTitle => 'Билдиришномалар';

  @override
  String get onboardingNotifBody =>
      'Илова ҳар бир намоз кирганини билдиради ва агар намоз ўқилди деб белгиланмаган бўлса, вақти тугашига 30 дақиқа қолганда яна эслатади.';

  @override
  String get notifModeSound => 'Овоз билан';

  @override
  String get notifModeSilent => 'Овозсиз';

  @override
  String get notifModeOff => 'Ўчирилган';

  @override
  String get calendarNotMarked => 'Белгиланмаган';

  @override
  String get calendarDayPanelKicker => 'Намозларни белгиланг';

  @override
  String get namesNoticeTitle => 'Ҳозирча фақат ўзбекча';

  @override
  String get namesNoticeBody =>
      'Аллоҳ исмлари ва уларнинг шарҳи ҳозирча фақат ўзбек (кирилл) тилида мавжуд. Бошқа тилларга таржималари кейинги янгиланишларда қўшилади.';

  @override
  String get namesNoticeButton => 'Тушунарли';

  @override
  String get feedbackKicker => 'Алоқа';

  @override
  String get feedbackEmail => 'Почтага ёзиш';

  @override
  String get feedbackTelegram => 'Телеграмга ёзиш';

  @override
  String get feedbackCopied => 'Нусхаланди';

  @override
  String appVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get namesNoticeDisclaimer =>
      'Ёзилиши ва шарҳларида хатолар бўлиши мумкин. Хатони сезсангиз, созламалардаги «Алоқа» бўлими орқали ёзинг.';

  @override
  String get namesDisclaimerTitle => 'Эътибор беринг';
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
  String get widgetMarkedLabel => 'Bajarildi';

  @override
  String get widgetNoDataLabel => 'Ilovani oching';

  @override
  String get nowBarTitle => 'Now Bar';

  @override
  String get persistentNotifTitle => 'Doimiy bildirishnoma';

  @override
  String get nowBarDescription => 'Joriy namoz Now Bar\'da ko\'rsatiladi.';

  @override
  String get persistentNotifDescription =>
      'Joriy namoz bildirishnomalarda ko\'rsatiladi.';

  @override
  String get nowBarSwitchLabel => 'Now Bar\'da ko\'rsatish';

  @override
  String get persistentNotifSwitchLabel => 'Bildirishnomani ko\'rsatish';

  @override
  String get infoButtonLabel => 'Batafsil';

  @override
  String get nowBarOn => 'Yoqilgan';

  @override
  String get nowBarOff => 'O\'chirilgan';

  @override
  String get nowBarNotificationsOff =>
      'Telefon sozlamalarida ilova bildirishnomalari o\'chirilgan, shuning uchun u ko\'rinmaydi.';

  @override
  String get nowBarOpenSettings => 'Telefon sozlamalarini ochish';

  @override
  String get nowBarOpenAction => 'Ochish';

  @override
  String get nowBarEndsIn => 'Tugashiga';

  @override
  String get nowBarStartsIn => 'Boshlanishiga';

  @override
  String get nowBarChannelName => 'Joriy namoz';

  @override
  String get nowBarScheduleLabel => 'Barcha namozlarni ko\'rsatish';

  @override
  String get nowBarScheduleDescription =>
      'Barcha namozlar Now Bar\'da ko\'rsatiladi.';

  @override
  String get nowBarScheduleDescriptionPlain =>
      'Barcha namozlar bildirishnomalarda ko\'rsatiladi.';

  @override
  String get nowBarDevTitle => 'Bu telefonda Now Bar hali o\'chiq';

  @override
  String get nowBarDevBody =>
      'Samsung boshqa ilovalarni Now Bar\'ga faqat «Ishlab chiqaruvchi opsiyalari» ichidagi kalit yoqilgandan keyin chiqaradi. Unga qadar namoz oddiy bildirishnoma bo\'lib ko\'rinadi.';

  @override
  String get nowBarDevStepAbout =>
      '«Sozlamalar» → «Telefon haqida» → «Dastur haqida ma’lumot» bo\'limini oching.';

  @override
  String get nowBarDevStepBuildNumber =>
      '«Reliz raqami» ustiga ketma-ket 7 marta bosing va telefon so\'rasa, PIN-kodni kiriting. «Ishlab chiqaruvchi opsiyalari» paydo bo\'ladi.';

  @override
  String get nowBarDevStepDeveloperOptions =>
      '«Sozlamalar»ga qayting va ro\'yxatning eng pastidagi «Ishlab chiqaruvchi opsiyalari» bo\'limini oching.';

  @override
  String get nowBarDevStepSwitch =>
      '«Hamma ilv. u-n jonli bildir-lar» bandini toping va yoqing.';

  @override
  String get nowBarDevOpenAbout => '«Telefon haqida»ni ochish';

  @override
  String get nowBarDevOpenDeveloper =>
      '«Ishlab chiqaruvchi opsiyalari»ni ochish';

  @override
  String onboardingStepLabel(int current, int total) {
    return '$current-qadam, jami $total';
  }

  @override
  String get onboardingNext => 'Keyingisi';

  @override
  String get onboardingBack => 'Orqaga';

  @override
  String get onboardingFinish => 'Tayyor';

  @override
  String get onboardingLanguageTitle => 'Ilova tili';

  @override
  String get onboardingLanguageBody =>
      'Namoz nomlari, maslahatlar va bildirishnomalar shu tilda bo\'ladi. Istalgan vaqtda sozlamalardan o\'zgartirasiz.';

  @override
  String get onboardingThemeTitle => 'Ko\'rinishi';

  @override
  String get onboardingThemeBody =>
      'Yorug\', qorong\'i yoki telefondagidek. Bosh ekrandagi vidjet ham shu tanlovga ergashadi.';

  @override
  String get onboardingCityTitle => 'Shahringiz';

  @override
  String get onboardingCityBody =>
      'Namoz vaqtlari koordinatalarga bog\'liq, shuning uchun shahar eng muhim sozlama. Uni avtomatik aniqlang yoki o\'zingiz tanlang.';

  @override
  String get onboardingCityDetect => 'Avtomatik aniqlash';

  @override
  String get onboardingCityManual => 'O\'zim tanlayman';

  @override
  String get onboardingCitySelected => 'Tanlangan shahar';

  @override
  String get onboardingMethodTitle => 'Hisoblash usuli';

  @override
  String get onboardingMethodBody =>
      'Tashkilotlar bomdod va xufton uchun quyoshning turli burchaklaridan foydalanadi, shuning uchun vaqtlar bir necha daqiqaga farq qiladi. Yashaydigan joyingizda qabul qilinganini tanlang.';

  @override
  String get onboardingMadhabTitle => 'Mazhab';

  @override
  String get onboardingMadhabBody =>
      'Bu faqat asr vaqtiga ta\'sir qiladi: hanafiylarda u shofiylarnikidan kechroq kiradi.';

  @override
  String get onboardingNotifTitle => 'Bildirishnomalar';

  @override
  String get onboardingNotifBody =>
      'Ilova har bir namoz kirganini bildiradi va agar namoz o\'qildi deb belgilanmagan bo\'lsa, vaqti tugashiga 30 daqiqa qolganda yana eslatadi.';

  @override
  String get notifModeSound => 'Ovoz bilan';

  @override
  String get notifModeSilent => 'Ovozsiz';

  @override
  String get notifModeOff => 'O\'chirilgan';

  @override
  String get calendarNotMarked => 'Belgilanmagan';

  @override
  String get calendarDayPanelKicker => 'Namozlarni belgilang';

  @override
  String get namesNoticeTitle => 'Hozircha faqat o\'zbekcha';

  @override
  String get namesNoticeBody =>
      'Alloh ismlari va ularning sharhi hozircha faqat o\'zbek (kirill) tilida mavjud. Boshqa tillarga tarjimalari keyingi yangilanishlarda qo\'shiladi.';

  @override
  String get namesNoticeButton => 'Tushunarli';

  @override
  String get feedbackKicker => 'Aloqa';

  @override
  String get feedbackEmail => 'Pochtaga yozish';

  @override
  String get feedbackTelegram => 'Telegramga yozish';

  @override
  String get feedbackCopied => 'Nusxalandi';

  @override
  String appVersionLabel(String version) {
    return 'Versiya $version';
  }

  @override
  String get namesNoticeDisclaimer =>
      'Yozilishi va sharhlarida xatolar bo\'lishi mumkin. Xatoni sezsangiz, sozlamalardagi «Aloqa» bo\'limi orqali yozing.';

  @override
  String get namesDisclaimerTitle => 'E\'tibor bering';
}
