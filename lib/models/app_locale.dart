import 'package:flutter/material.dart';

enum AppLocale {
  ru,
  en,
  uzCyrillic,
  uzLatin;

  static AppLocale fromName(String? name) => AppLocale.values.firstWhere(
    (l) => l.name == name,
    orElse: () => AppLocale.ru,
  );

  /// Maps the device's system locale to the closest supported [AppLocale] —
  /// used only for the very first launch, before the user has picked a
  /// language of their own (see AppState._restore). Falls back to Russian
  /// for anything unsupported, matching [fromName]'s fallback.
  static AppLocale fromSystemLocale(Locale locale) {
    if (locale.languageCode == 'uz') {
      return locale.scriptCode == 'Cyrl'
          ? AppLocale.uzCyrillic
          : AppLocale.uzLatin;
    }
    return AppLocale.values.firstWhere(
      (l) => l.localeValue.languageCode == locale.languageCode,
      orElse: () => AppLocale.ru,
    );
  }
}

extension AppLocaleInfo on AppLocale {
  String get label => switch (this) {
    AppLocale.ru => 'Русский',
    AppLocale.en => 'English',
    AppLocale.uzCyrillic => 'Ўзбекча (кирилл)',
    AppLocale.uzLatin => "O'zbekcha (lotin)",
  };

  Locale get localeValue => switch (this) {
    AppLocale.ru => const Locale('ru'),
    AppLocale.en => const Locale('en'),
    AppLocale.uzCyrillic => const Locale.fromSubtags(
      languageCode: 'uz',
      scriptCode: 'Cyrl',
    ),
    AppLocale.uzLatin => const Locale.fromSubtags(
      languageCode: 'uz',
      scriptCode: 'Latn',
    ),
  };
}
