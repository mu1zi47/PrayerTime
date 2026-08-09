import 'package:flutter/material.dart';

/// The UI language. Persisted and switchable from Settings — none of the
/// app's strings are translated yet (see the language picker's doc
/// comment), so picking one currently only changes this preference, not
/// the visible text.
enum AppLocale {
  ru,
  en,
  uzCyrillic,
  uzLatin;

  static AppLocale fromName(String? name) =>
      AppLocale.values.firstWhere((l) => l.name == name, orElse: () => AppLocale.ru);
}

extension AppLocaleInfo on AppLocale {
  String get label => switch (this) {
    AppLocale.ru => 'Русский',
    AppLocale.en => 'English',
    AppLocale.uzCyrillic => 'Ўзбекча (кирилл)',
    AppLocale.uzLatin => "O'zbekcha (lotin)",
  };

  /// Not yet wired into `MaterialApp.locale` — kept ready for when the
  /// app's strings are actually translated.
  Locale get localeValue => switch (this) {
    AppLocale.ru => const Locale('ru'),
    AppLocale.en => const Locale('en'),
    AppLocale.uzCyrillic => const Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
    AppLocale.uzLatin => const Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Latn'),
  };
}
