import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/azan_sounds.dart';
import '../data/next_prayer.dart';
import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../services/notification_service.dart';
import '../services/now_bar_support.dart';
import '../services/prayer_times_api.dart';
import '../widgets/prayer_icon.dart';

const _kCity = 'city';
const _kMadhab = 'madhab';
const _kQuiet = 'quiet';
const _kAzanSound = 'azan_sound';
const _kNotifPrefix = 'notif_';
const _kThemeMode = 'theme_mode';
const _kLocale = 'locale';
const _kNowBarCurrent = 'now_bar_current';
const _kNowBarNext = 'now_bar_next';
const _kFavoriteNames = 'favorite_allah_names';
const _kMethod = 'method';
const _kPrayerLog = 'prayer_log';

class AppState extends ChangeNotifier {
  AppState({PrayerTimesApi? api, NotificationService? notifications})
      : _api = api ?? PrayerTimesApi(),
        _notifications = notifications ?? NotificationService();

  final PrayerTimesApi _api;
  final NotificationService _notifications;

  String _method = 'uzbekistan';
  String _madhab = 'hanafi';
  String _selectedCityId = 'tashkent';
  bool _quiet = false;
  String _azanSoundId = AzanSounds.all.first.id;
  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _locale = AppLocale.ru;
  bool _nowBarCurrentPrayer = true;
  bool _nowBarNextPrayer = true;
  bool _nowBarSupported = false;
  bool _nowBarPermissionGranted = false;
  Timer? _nowBarTicker;
  final Set<int> _favoriteNames = {};

  final Map<String, Map<String, PrayerLogStatus>> _prayerLog = {};

  final Map<String, NotifMode> _notifMode = {
    'fajr': NotifMode.notification,
    'zuhr': NotifMode.notification,
    'asr': NotifMode.notification,
    'maghrib': NotifMode.notification,
    'isha': NotifMode.notification,
  };

  List<PrayerDay> _days = [];
  bool _isLoadingDays = false;
  String? _daysError;
  int _requestGeneration = 0;

  String get method => _method;
  String get methodLabel => methodLabelFor(_t, _resolvedMethod.id);
  String get madhab => _madhab;
  String get selectedCityId => _selectedCityId;
  bool get quiet => _quiet;
  String get azanSoundId => _azanSoundId;
  ThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;
  bool get nowBarCurrentPrayer => _nowBarCurrentPrayer;
  bool get nowBarNextPrayer => _nowBarNextPrayer;
  bool get nowBarSupported => _nowBarSupported;
  bool get nowBarPermissionGranted => _nowBarPermissionGranted;
  Set<int> get favoriteNames => Set.unmodifiable(_favoriteNames);
  bool isFavoriteName(int number) => _favoriteNames.contains(number);

  Map<String, PrayerLogStatus> prayerLogFor(DateTime date) =>
      Map.unmodifiable(_prayerLog[_dateKey(date)] ?? const {});
  PrayerLogStatus? prayerStatusFor(DateTime date, String prayerKey) => _prayerLog[_dateKey(date)]?[prayerKey];
  Map<String, NotifMode> get notifMode => Map.unmodifiable(_notifMode);
  NotificationService get notifications => _notifications;

  List<PrayerDay> get days => _days;
  bool get isLoadingDays => _isLoadingDays;
  String? get daysError => _daysError;

  City get _city => ReferenceData.cities.firstWhere(
        (c) => c.id == _selectedCityId,
        orElse: () => ReferenceData.cities.first,
      );

  PrayerMethod get _resolvedMethod =>
      ReferenceData.methods.firstWhere((m) => m.id == _method, orElse: () => ReferenceData.methods.first);

  int get _methodCode => _resolvedMethod.aladhanCode;
  String? get _methodTune => _resolvedMethod.tune;

  int get _school => _madhab == 'hanafi' ? 1 : 0;

  /// Localized strings in the currently selected [locale] — for text built
  /// outside a widget's `build()` (Now Bar, scheduled-notification titles),
  /// where there's no BuildContext to pull `AppLocalizations.of(context)`
  /// from.
  AppLocalizations get _t => lookupAppLocalizations(_locale.localeValue);

  DateTime get cityNow => DateTime.now().toUtc().add(Duration(hours: _city.utcOffsetHours));

  Future<void> init() async {
    await _restore();
    try {
      await _notifications.init().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignored — see doc comment above.
    }
    _nowBarSupported = await NowBarSupport.isAvailable();
    if (_nowBarSupported) {
      _nowBarPermissionGranted = await _notifications.canPostPromotedNotifications();
    }
    _nowBarTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshNowBarPermission();
      _refreshNowBar();
    });
    await loadPrayerTimes();
  }

  @override
  void dispose() {
    _nowBarTicker?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCityId = prefs.getString(_kCity) ?? _selectedCityId;
    _method = prefs.getString(_kMethod) ?? _method;
    _madhab = prefs.getString(_kMadhab) ?? _madhab;
    _quiet = prefs.getBool(_kQuiet) ?? _quiet;
    _azanSoundId = prefs.getString(_kAzanSound) ?? _azanSoundId;
    _themeMode = _themeModeFromName(prefs.getString(_kThemeMode));
    _locale = AppLocale.fromName(prefs.getString(_kLocale));
    _nowBarCurrentPrayer = prefs.getBool(_kNowBarCurrent) ?? _nowBarCurrentPrayer;
    _nowBarNextPrayer = prefs.getBool(_kNowBarNext) ?? _nowBarNextPrayer;
    _favoriteNames
      ..clear()
      ..addAll((prefs.getStringList(_kFavoriteNames) ?? const []).map(int.parse));
    final logRaw = prefs.getString(_kPrayerLog);
    _prayerLog.clear();
    if (logRaw != null) {
      try {
        final decoded = jsonDecode(logRaw) as Map<String, dynamic>;
        for (final dayEntry in decoded.entries) {
          final day = <String, PrayerLogStatus>{};
          for (final prayerEntry in (dayEntry.value as Map<String, dynamic>).entries) {
            final status = PrayerLogStatus.fromName(prayerEntry.value as String);
            if (status != null) day[prayerEntry.key] = status;
          }
          if (day.isNotEmpty) _prayerLog[dayEntry.key] = day;
        }
      } catch (_) {
        // Ignored — corrupt/unreadable log starts fresh rather than crashing.
      }
    }
    for (final key in _notifMode.keys) {
      final saved = prefs.getString('$_kNotifPrefix$key');
      if (saved != null) _notifMode[key] = NotifMode.fromName(saved);
    }
    notifyListeners();
  }

  Future<void> loadPrayerTimes() async {
    final generation = ++_requestGeneration;
    _isLoadingDays = true;
    _daysError = null;
    notifyListeners();

    final city = _city;
    final now = cityNow;

    try {
      final fetched = await _api.fetchUpcomingDays(
        city: city,
        methodCode: _methodCode,
        school: _school,
        tune: _methodTune,
        from: DateTime(now.year, now.month, now.day),
      );
      if (generation != _requestGeneration) return;
      _days = fetched;
      _isLoadingDays = false;
      notifyListeners();
      _reschedule();
      _refreshNowBar();
    } catch (e) {
      if (generation != _requestGeneration) return;
      _isLoadingDays = false;
      _daysError = e is PrayerApiException ? _apiErrorMessage(e.error) : _t.genericLoadError;
      notifyListeners();
    }
  }

  String _apiErrorMessage(PrayerApiError error) => switch (error) {
        PrayerApiError.timeout => _t.errorTimeout,
        PrayerApiError.noConnection => _t.errorNoConnection,
        PrayerApiError.serviceUnavailable => _t.errorServiceUnavailable,
        PrayerApiError.parseFailed => _t.errorParseFailed,
        PrayerApiError.fetchFailed => _t.errorFetchFailed,
      };

  void _reschedule() {
    if (_days.isEmpty) return;
    // Fire-and-forget, best-effort — a scheduling failure shouldn't
    // surface as an app-breaking error (see [init]).
    _notifications
        .scheduleForDays(
          days: _days,
          notifMode: _notifMode,
          azanSoundId: _azanSoundId,
          utcOffsetHours: _city.utcOffsetHours,
          locale: _locale,
          quietHoursEnabled: _quiet,
        )
        .catchError((_) {});
  }

  void selectMadhab(String id) {
    _madhab = id;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kMadhab, id));
  }

  void selectCity(String cityId) {
    _selectedCityId = cityId;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kCity, cityId));
  }

  void selectMethod(String id) {
    _method = id;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kMethod, id));
  }

  void setNotifMode(String key, NotifMode mode) {
    _notifMode[key] = mode;
    notifyListeners();
    _reschedule();
    _save((p) => p.setString('$_kNotifPrefix$key', mode.name));
  }

  void selectAzanSound(String id) {
    _azanSoundId = id;
    notifyListeners();
    _reschedule();
    _save((p) => p.setString(_kAzanSound, id));
  }

  void toggleQuiet() {
    _quiet = !_quiet;
    notifyListeners();
    _save((p) => p.setBool(_kQuiet, _quiet));
    _reschedule();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _save((p) => p.setString(_kThemeMode, mode.name));
  }

  void setLocale(AppLocale locale) {
    _locale = locale;
    notifyListeners();
    _save((p) => p.setString(_kLocale, locale.name));
    // Scheduled-notification titles and the Now Bar text are both built
    // eagerly (see [_t]'s doc comment) — refresh them so they pick up the
    // new language too, not just the UI.
    _reschedule();
    _refreshNowBar();
  }

  void toggleFavoriteName(int number) {
    if (!_favoriteNames.remove(number)) _favoriteNames.add(number);
    notifyListeners();
    _save((p) => p.setStringList(_kFavoriteNames, _favoriteNames.map((n) => n.toString()).toList()));
  }

  void setPrayerStatus(DateTime date, String prayerKey, PrayerLogStatus? status) {
    final key = _dateKey(date);
    final day = _prayerLog.putIfAbsent(key, () => {});
    if (status == null || day[prayerKey] == status) {
      day.remove(prayerKey);
    } else {
      day[prayerKey] = status;
    }
    if (day.isEmpty) _prayerLog.remove(key);
    notifyListeners();
    _save(
      (p) => p.setString(
        _kPrayerLog,
        jsonEncode(_prayerLog.map((k, v) => MapEntry(k, v.map((pk, status) => MapEntry(pk, status.name))))),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Settings for Samsung's "Now Bar" (One UI 7+'s Dynamic-Island-style
  // surface for ongoing notifications) — see [NowBarSupport] for how
  // device eligibility is determined.
  void toggleNowBarCurrentPrayer() {
    _nowBarCurrentPrayer = !_nowBarCurrentPrayer;
    notifyListeners();
    _save((p) => p.setBool(_kNowBarCurrent, _nowBarCurrentPrayer));
    _refreshNowBar();
  }

  void toggleNowBarNextPrayer() {
    _nowBarNextPrayer = !_nowBarNextPrayer;
    notifyListeners();
    _save((p) => p.setBool(_kNowBarNext, _nowBarNextPrayer));
    _refreshNowBar();
  }

  Future<void> refreshNowBarPermission() async {
    if (!_nowBarSupported) return;
    final granted = await _notifications.canPostPromotedNotifications();
    if (granted != _nowBarPermissionGranted) {
      _nowBarPermissionGranted = granted;
      notifyListeners();
    }
  }

  Future<void> openNowBarSettings() => _notifications.openPromotedNotificationSettings();

  void _refreshNowBar() {
    if (!_nowBarSupported) return;
    if (_days.isEmpty || (!_nowBarCurrentPrayer && !_nowBarNextPrayer)) {
      _notifications.cancelNowBar();
      return;
    }

    final now = cityNow;
    final current = computeCurrentPrayer(_days, now);
    final next = computeNextPrayer(_days, now);
    final t = _t;

    final lines = <String>[
      if (_nowBarCurrentPrayer && current != null) t.nowBarCurrentLine(nameForPrayer(t, current)),
      if (_nowBarNextPrayer && next != null) t.nowBarNextLine(nameForPrayer(t, next.kind), next.time),
    ];

    if (lines.isEmpty) {
      _notifications.cancelNowBar();
      return;
    }

    // The short, glanceable text shown in the Now Bar's compact pill —
    // prefers whichever of current/next is actually enabled.
    final shortText = _nowBarCurrentPrayer && current != null
        ? nameForPrayer(t, current)
        : (next != null ? nameForPrayer(t, next.kind) : '');

    _notifications.showNowBar(title: t.nowBarNotificationTitle, body: lines.join(' · '), shortText: shortText);
  }

  static ThemeMode _themeModeFromName(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

  Future<void> _save(Future<void> Function(SharedPreferences) write) async {
    final prefs = await SharedPreferences.getInstance();
    await write(prefs);
  }
}
