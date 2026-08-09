import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/azan_sounds.dart';
import '../data/next_prayer.dart';
import '../data/reference_data.dart';
import '../models/app_locale.dart';
import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
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

/// Mirrors the design's `Component.state` — one shared, observable
/// state object for selections made across the Home/Settings/City/
/// Notifications screens, plus the fetched prayer schedule itself.
///
/// City/madhab/notification choices are persisted locally (see [init])
/// so they survive an app restart.
class AppState extends ChangeNotifier {
  AppState({PrayerTimesApi? api, NotificationService? notifications})
      : _api = api ?? PrayerTimesApi(),
        _notifications = notifications ?? NotificationService();

  final PrayerTimesApi _api;
  final NotificationService _notifications;

  final String _method = 'mwl';
  String _madhab = 'hanafi';
  String _selectedCity = 'Ташкент';
  bool _quiet = false;
  String _azanSoundId = AzanSounds.all.first.id;
  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _locale = AppLocale.ru;
  bool _nowBarCurrentPrayer = true;
  bool _nowBarNextPrayer = true;
  bool _nowBarSupported = false;
  bool _nowBarPermissionGranted = false;
  Timer? _nowBarTicker;

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
  String get madhab => _madhab;
  String get selectedCity => _selectedCity;
  bool get quiet => _quiet;
  String get azanSoundId => _azanSoundId;
  ThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;
  bool get nowBarCurrentPrayer => _nowBarCurrentPrayer;
  bool get nowBarNextPrayer => _nowBarNextPrayer;
  bool get nowBarSupported => _nowBarSupported;
  bool get nowBarPermissionGranted => _nowBarPermissionGranted;
  Map<String, NotifMode> get notifMode => Map.unmodifiable(_notifMode);
  NotificationService get notifications => _notifications;

  List<PrayerDay> get days => _days;
  bool get isLoadingDays => _isLoadingDays;
  String? get daysError => _daysError;

  City get _city => ReferenceData.cities.firstWhere(
        (c) => c.name == _selectedCity,
        orElse: () => ReferenceData.cities.first,
      );

  int get _methodCode => ReferenceData.methods
      .firstWhere((m) => m.id == _method, orElse: () => ReferenceData.methods.first)
      .aladhanCode;

  int get _school => _madhab == 'hanafi' ? 1 : 0;

  /// Current wall-clock time in the selected city (see [City.utcOffsetHours]).
  DateTime get cityNow => DateTime.now().toUtc().add(Duration(hours: _city.utcOffsetHours));

  /// Loads persisted settings (if any), starts the notification service,
  /// then fetches the schedule. Call once on startup.
  ///
  /// Notification setup is best-effort: on a platform/browser where it
  /// isn't fully supported (or the user denies permission), that must
  /// never block the app from showing prayer times at all.
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
    _selectedCity = prefs.getString(_kCity) ?? _selectedCity;
    _madhab = prefs.getString(_kMadhab) ?? _madhab;
    _quiet = prefs.getBool(_kQuiet) ?? _quiet;
    _azanSoundId = prefs.getString(_kAzanSound) ?? _azanSoundId;
    _themeMode = _themeModeFromName(prefs.getString(_kThemeMode));
    _locale = AppLocale.fromName(prefs.getString(_kLocale));
    _nowBarCurrentPrayer = prefs.getBool(_kNowBarCurrent) ?? _nowBarCurrentPrayer;
    _nowBarNextPrayer = prefs.getBool(_kNowBarNext) ?? _nowBarNextPrayer;
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
      _daysError = e is PrayerApiException ? e.message : 'Не удалось загрузить времена намаза.';
      notifyListeners();
    }
  }

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
        )
        .catchError((_) {});
  }

  void selectMadhab(String id) {
    _madhab = id;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kMadhab, id));
  }

  void selectCity(String city) {
    _selectedCity = city;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kCity, city));
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
  }

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

  /// Re-checks the OS-level "allow promoted notifications" toggle (see
  /// [NotificationService.canPostPromotedNotifications]) and notifies if it
  /// changed — e.g. after the user comes back from [openNowBarSettings].
  Future<void> refreshNowBarPermission() async {
    if (!_nowBarSupported) return;
    final granted = await _notifications.canPostPromotedNotifications();
    if (granted != _nowBarPermissionGranted) {
      _nowBarPermissionGranted = granted;
      notifyListeners();
    }
  }

  Future<void> openNowBarSettings() => _notifications.openPromotedNotificationSettings();

  /// Pushes the current/next prayer (per the two toggles above) into the
  /// ongoing Now Bar notification, or cancels it if there's nothing to
  /// show. Called on a 1-minute tick, whenever the schedule reloads, and
  /// whenever either toggle changes.
  void _refreshNowBar() {
    if (!_nowBarSupported) return;
    if (_days.isEmpty || (!_nowBarCurrentPrayer && !_nowBarNextPrayer)) {
      _notifications.cancelNowBar();
      return;
    }

    final now = cityNow;
    final current = computeCurrentPrayer(_days, now);
    final next = computeNextPrayer(_days, now);

    final lines = <String>[
      if (_nowBarCurrentPrayer && current != null) 'Сейчас: ${nameForPrayer(current)}',
      if (_nowBarNextPrayer && next != null) 'Далее: ${nameForPrayer(next.kind)} в ${next.time}',
    ];

    if (lines.isEmpty) {
      _notifications.cancelNowBar();
      return;
    }

    // The short, glanceable text shown in the Now Bar's compact pill —
    // prefers whichever of current/next is actually enabled.
    final shortText = _nowBarCurrentPrayer && current != null
        ? nameForPrayer(current)
        : (next != null ? nameForPrayer(next.kind) : '');

    _notifications.showNowBar(title: 'Намаз', body: lines.join(' · '), shortText: shortText);
  }

  static ThemeMode _themeModeFromName(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

  Future<void> _save(Future<void> Function(SharedPreferences) write) async {
    final prefs = await SharedPreferences.getInstance();
    await write(prefs);
  }
}
