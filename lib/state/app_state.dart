import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/notif_mode.dart';
import '../models/prayer_day.dart';
import '../models/prayer_log_status.dart';
import '../services/connectivity_service.dart';
import '../services/home_widget_bridge.dart';
import '../services/notification_service.dart';
import '../services/prayer_cache_store.dart';
import '../services/prayer_log_store.dart';
import '../services/prayer_times_api.dart';

const _kCity = 'city';
const _kCityV2 = 'city_v2';
const _kMadhab = 'madhab';
const _kQuiet = 'quiet';
const _kNotifPrefix = 'notif_';
const _kThemeMode = 'theme_mode';
const _kLocale = 'locale';
const _kFavoriteNames = 'favorite_allah_names';
const _kMethod = 'method';
const _kTahajjudEnabled = 'tahajjud_enabled';
const _kOnboardingDone = 'onboarding_done';
const _kOnboardingInstall = 'onboarding_install_time';

/// When this copy of the app was first installed and last updated, as the
/// platform reports them — what tells a fresh install carrying settings
/// restored from a backup apart from one that has been set up all along
/// (see AppState._restore).
typedef InstallTimes = ({DateTime installed, DateTime updated});

Future<InstallTimes?> _platformInstallTimes() async {
  try {
    // Bounded: restoring settings waits on this, and a platform that never
    // answers would otherwise leave the app on a blank first frame.
    final info = await PackageInfo.fromPlatform().timeout(
      const Duration(seconds: 2),
    );
    final installed = info.installTime;
    final updated = info.updateTime;
    if (installed == null || updated == null) return null;
    return (installed: installed, updated: updated);
  } catch (_) {
    // No platform to ask (tests, or a platform the plugin doesn't cover):
    // setup falls back to going by what's on disk alone.
    return null;
  }
}

// The home screen's day window: enough of the past that the current-prayer
// calculation always has yesterday on hand (see computeCurrentPrayer's
// todayIndex fallback), and enough of the future for a useful offline
// preview range — see AppState.loadPrayerTimes.
const _pastDays = 7;
const _futureDays = 7;

class AppState extends ChangeNotifier {
  AppState({
    PrayerTimesApi? api,
    NotificationService? notifications,
    PrayerCacheStore? cache,
    ConnectivityService? connectivity,
    HomeWidgetBridge? homeWidget,
    Future<InstallTimes?> Function()? installTimes,
  }) : _api = api ?? PrayerTimesApi(),
       _notifications = notifications ?? NotificationService(),
       _cache = cache ?? const PrayerCacheStore(),
       _connectivity = connectivity ?? const ConnectivityService(),
       _homeWidget = homeWidget ?? const HomeWidgetBridge(),
       _installTimes = installTimes ?? _platformInstallTimes;

  final PrayerTimesApi _api;
  final NotificationService _notifications;
  final PrayerCacheStore _cache;
  final ConnectivityService _connectivity;
  final HomeWidgetBridge _homeWidget;
  final Future<InstallTimes?> Function() _installTimes;

  /// This install's first-install time, once read — what completing setup
  /// records it ran on.
  int? _installedAtMs;
  AppLifecycleListener? _lifecycle;
  Timer? _rescheduleDebounce;

  String _method = 'uzbekistan';
  String _madhab = 'hanafi';
  City _selectedCity = ReferenceData.cities.firstWhere(
    (c) => c.id == 'tashkent',
  );
  bool _quiet = false;
  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _locale = AppLocale.ru;
  final Set<int> _favoriteNames = {};
  bool _tahajjudEnabled = false;

  bool _onboardingDone = false;
  bool _restored = false;

  final Map<String, Map<String, PrayerLogStatus>> _prayerLog = {};

  final Map<String, NotifMode> _notifMode = {
    'tahajjud': NotifMode.notification,
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
  City get selectedCity => _selectedCity;
  String get selectedCityId => _selectedCity.id;
  String cityLabel(AppLocalizations t) => cityNameFor(t, _selectedCity);
  bool get quiet => _quiet;
  ThemeMode get themeMode => _themeMode;
  AppLocale get locale => _locale;
  bool get tahajjudEnabled => _tahajjudEnabled;

  /// False until the first-run setup flow has been walked through — see
  /// OnboardingScreen. Everything it asks for has a working default, so the
  /// app is fully usable behind it; it's about making the choices explicit
  /// rather than leaving someone on Tashkent's schedule by accident.
  bool get onboardingDone => _onboardingDone;

  /// Whether persisted settings have been read back yet. The entry point
  /// waits on this so it doesn't flash the setup flow at someone who
  /// finished it months ago.
  bool get isRestored => _restored;
  Set<int> get favoriteNames => Set.unmodifiable(_favoriteNames);
  bool isFavoriteName(int number) => _favoriteNames.contains(number);

  Map<String, PrayerLogStatus> prayerLogFor(DateTime date) =>
      Map.unmodifiable(_prayerLog[_dateKey(date)] ?? const {});
  PrayerLogStatus? prayerStatusFor(DateTime date, String prayerKey) =>
      _prayerLog[_dateKey(date)]?[prayerKey];
  Map<String, NotifMode> get notifMode => Map.unmodifiable(_notifMode);
  NotificationService get notifications => _notifications;

  List<PrayerDay> get days => _days;
  bool get isLoadingDays => _isLoadingDays;
  String? get daysError => _daysError;

  /// Index of "today" within [days] — [days] spans [_pastDays] before it
  /// through [_futureDays] after, so unlike before, it's not always 0. Falls
  /// back to the closest date on hand if today's own entry is missing (a
  /// cache stale enough to no longer straddle the real today).
  int get todayIndex {
    if (_days.isEmpty) return 0;
    final today = DateTime(cityNow.year, cityNow.month, cityNow.day);
    final exact = _days.indexWhere((d) => _isSameDate(d.date, today));
    if (exact != -1) return exact;
    var closest = 0;
    var bestDiff = _days.first.date.difference(today).abs();
    for (var i = 1; i < _days.length; i++) {
      final diff = _days[i].date.difference(today).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  PrayerDay? get todayPrayerDay => _days.isEmpty ? null : _days[todayIndex];

  /// The prayer-day currently "in progress", for logging purposes —
  /// distinct from [todayIndex]'s plain calendar date. Between midnight and
  /// today's own Fajr, the night before's Isha window hasn't closed yet, so
  /// the anchor stays on yesterday's date until Fajr actually arrives (the
  /// same boundary `computeCurrentPrayer` uses for "current prayer").
  DateTime get _prayerDayAnchor {
    final now = cityNow;
    final calendarToday = DateTime(now.year, now.month, now.day);
    PrayerDay? todayRecord;
    for (final d in _days) {
      if (_isSameDate(d.date, calendarToday)) {
        todayRecord = d;
        break;
      }
    }
    if (todayRecord != null &&
        now.isBefore(_utcCombine(todayRecord.date, todayRecord.fajr))) {
      return calendarToday.subtract(const Duration(days: 1));
    }
    return calendarToday;
  }

  /// True once a day is old enough to be judged — strictly before the day
  /// preceding the current prayer-day. The calendar uses it to tell "not
  /// judged yet" (today, or yesterday, which someone may still be filling
  /// in) apart from "judged and missed". It says nothing about whether a
  /// day can still be marked: any past day can, from either the calendar or
  /// the home screen's day strip.
  bool isDayLocked(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final yesterday = _prayerDayAnchor.subtract(const Duration(days: 1));
    return target.isBefore(yesterday);
  }

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _utcCombine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  PrayerMethod get _resolvedMethod => ReferenceData.methods.firstWhere(
    (m) => m.id == _method,
    orElse: () => ReferenceData.methods.first,
  );

  int get _methodCode => _resolvedMethod.aladhanCode;
  String? get _methodTune => _resolvedMethod.tune;

  int get _school => _madhab == 'hanafi' ? 1 : 0;

  /// Localized strings in the currently selected [locale] — for text built
  /// outside a widget's `build()` (scheduled-notification titles), where
  /// there's no BuildContext to pull `AppLocalizations.of(context)` from.
  AppLocalizations get _t => lookupAppLocalizations(_locale.localeValue);

  DateTime get cityNow => DateTime.now().toUtc().add(_selectedCity.utcOffset);

  Future<void> init() async {
    await _restore();
    // The home-screen widget writes the prayer log straight to disk, behind
    // this object's own in-memory copy (see HomeWidgetBridge) — so whatever
    // was marked from the widget while the app sat in the background is
    // picked up the moment the app comes back to the foreground.
    _lifecycle = AppLifecycleListener(onResume: _reloadPrayerLog);
    // Routes the notification's "Прочитал"/"Done" action through the same
    // path the "Мои намазы" screen itself uses, so it updates in-memory
    // state (and notifies listeners) rather than only the disk copy.
    _notifications.onMarkDone = (date, prayerKey) async =>
        setPrayerStatus(date, prayerKey, PrayerLogStatus.onTime);
    try {
      await _notifications.init().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignored — see doc comment above.
    }
    await loadPrayerTimes();
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _rescheduleDebounce?.cancel();
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final cityJson = prefs.getString(_kCityV2);
    if (cityJson != null) {
      try {
        _selectedCity = City.fromJson(
          jsonDecode(cityJson) as Map<String, dynamic>,
        );
      } catch (_) {
        // Ignored — corrupt/unreadable entry keeps the default city.
      }
    } else {
      // Migrates the old plain-id format from before custom (searched/GPS)
      // cities existed.
      final legacyId = prefs.getString(_kCity);
      if (legacyId != null) {
        _selectedCity = ReferenceData.cities.firstWhere(
          (c) => c.id == legacyId,
          orElse: () => _selectedCity,
        );
      }
    }
    _method = prefs.getString(_kMethod) ?? _method;
    _madhab = prefs.getString(_kMadhab) ?? _madhab;
    _quiet = prefs.getBool(_kQuiet) ?? _quiet;
    _themeMode = _themeModeFromName(prefs.getString(_kThemeMode));
    final savedLocale = prefs.getString(_kLocale);
    // First launch (nothing saved yet) follows the device's own language;
    // once the user has picked one — even by just landing on this default —
    // that choice is what's saved and respected from then on.
    _locale = savedLocale != null
        ? AppLocale.fromName(savedLocale)
        : AppLocale.fromSystemLocale(PlatformDispatcher.instance.locale);
    _tahajjudEnabled = prefs.getBool(_kTahajjudEnabled) ?? _tahajjudEnabled;
    // An install that predates this flow has settings on disk already —
    // treat that as "set up", rather than interrupting someone who has been
    // using the app for months with a first-run wizard.
    final hasSetup =
        prefs.getBool(_kOnboardingDone) ??
        (prefs.getString(_kCityV2) != null ||
            prefs.getString(_kCity) != null ||
            prefs.getString(_kLocale) != null);
    // Android's backup restores all of this onto a fresh install too. The
    // prayer log and settings are worth keeping, but a new install should
    // still start with setup — so setup records which install it ran on.
    // Settings from a different install came from a backup; so did
    // settings from before that was recorded, found on an install that has
    // never been updated (an in-place update from an older version always
    // has been).
    final times = await _installTimes();
    _installedAtMs = times?.installed.millisecondsSinceEpoch;
    final setupInstall = prefs.getInt(_kOnboardingInstall);
    final restoredOntoNewInstall =
        hasSetup &&
        times != null &&
        (setupInstall != null
            ? setupInstall != _installedAtMs
            : times.installed == times.updated);
    _onboardingDone = hasSetup && !restoredOntoNewInstall;
    final installedAt = _installedAtMs;
    if (_onboardingDone && installedAt != null && setupInstall != installedAt) {
      // An older version's setup, carried over by an in-place update: it
      // belongs to this install from now on.
      await prefs.setInt(_kOnboardingInstall, installedAt);
    }
    _favoriteNames
      ..clear()
      ..addAll(
        (prefs.getStringList(_kFavoriteNames) ?? const []).map(int.parse),
      );
    _prayerLog
      ..clear()
      ..addAll(_decodeLog(prefs.getString(kPrayerLogPrefsKey)));
    for (final key in _notifMode.keys) {
      final saved = prefs.getString('$_kNotifPrefix$key');
      if (saved != null) _notifMode[key] = NotifMode.fromName(saved);
    }
    _restored = true;
    notifyListeners();
  }

  String get _cacheSignature => PrayerCacheStore.signatureFor(
    cityId: _selectedCity.id,
    method: _method,
    madhab: _madhab,
  );

  Future<void> loadPrayerTimes() async {
    final generation = ++_requestGeneration;
    _isLoadingDays = true;
    _daysError = null;
    notifyListeners();

    final city = _selectedCity;
    final now = cityNow;
    final today = DateTime(now.year, now.month, now.day);
    final signature = _cacheSignature;

    // Show whatever's cached *before* going to the network, not just as a
    // fallback when it fails: a cold start otherwise sat on a spinner for a
    // full request (up to the 10s timeout) with a perfectly good schedule
    // already on disk. The fetch below still runs and replaces this.
    if (_days.isEmpty) {
      await _useCachedDays(
        generation,
        signature,
        fallbackError: null,
        quiet: true,
      );
      if (generation != _requestGeneration) return;
    }

    final online = await _connectivity.hasConnection();
    if (generation != _requestGeneration) return;

    if (!online) {
      await _useCachedDays(generation, signature, fallbackError: null);
      return;
    }

    try {
      final fetched = await _api.fetchDaysWindow(
        city: city,
        methodCode: _methodCode,
        school: _school,
        tune: _methodTune,
        centerDay: today,
        pastDays: _pastDays,
        futureDays: _futureDays,
      );
      if (generation != _requestGeneration) return;
      _days = fetched.days;
      // A custom (searched/GPS) city has no time zone up front — and even a
      // curated one is worth reconciling against what the API actually
      // resolved for its coordinates. Persist it so cityNow/notifications
      // stay correct without waiting on another fetch.
      if (fetched.timeZone.isNotEmpty &&
          fetched.timeZone != _selectedCity.timeZone) {
        _selectedCity = _selectedCity.withTimeZone(fetched.timeZone);
        _save((p) => p.setString(_kCityV2, jsonEncode(_selectedCity.toJson())));
      }
      _isLoadingDays = false;
      notifyListeners();
      _reschedule();
      _syncHomeWidget();
      // Keeps a rolling window of the max fetched days on disk, under the
      // current city/method/madhab, for the next offline launch.
      _cache.save(signature: signature, days: fetched.days);
    } catch (e) {
      if (generation != _requestGeneration) return;
      final fallbackError = e is PrayerApiException
          ? _apiErrorMessage(e.error)
          : _t.genericLoadError;
      await _useCachedDays(generation, signature, fallbackError: fallbackError);
    }
  }

  /// Serves whatever's cached for [signature] — including past days, so
  /// offline mode keeps its history/current-prayer context, not just
  /// today-onward — or falls back to [fallbackError] (or the generic
  /// no-connection message) when nothing usable is cached.
  /// [quiet] is for the warm-start pass in [loadPrayerTimes], where a fetch
  /// is still on its way: an empty cache there means "nothing to show yet",
  /// not "failed" — so it leaves the loading state alone instead of
  /// surfacing an error the network may be about to disprove.
  Future<void> _useCachedDays(
    int generation,
    String signature, {
    required String? fallbackError,
    bool quiet = false,
  }) async {
    final cached = await _cache.load(signature);
    if (generation != _requestGeneration) return;
    cached?.sort((a, b) => a.date.compareTo(b.date));

    if (cached != null && cached.isNotEmpty) {
      _days = cached;
      _isLoadingDays = false;
      _daysError = null;
      notifyListeners();
      _reschedule();
      _syncHomeWidget();
    } else if (!quiet) {
      _isLoadingDays = false;
      _daysError = fallbackError ?? _t.errorNoConnection;
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

  /// Rewrites the home-screen widget's own copy of the schedule (see
  /// [HomeWidgetBridge]) — it draws itself with no Flutter engine running,
  /// so it can't ask for any of this later.
  void _syncHomeWidget() {
    if (_days.isEmpty) return;
    _homeWidget
        .publish(
          days: _days,
          utcOffset: _selectedCity.utcOffset,
          themeMode: _themeMode,
          t: _t,
        )
        .catchError((_) {});
  }

  /// Debounced: rebuilding the schedule cancels and re-books up to ~180
  /// alarms across the platform channel, and a settings screen can fire
  /// several changes in a row (three notification modes, quiet hours,
  /// Tahajjud). Without this each tap paid for the whole rebuild.
  void _reschedule() {
    if (_days.isEmpty) return;
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(
      const Duration(milliseconds: 400),
      _rescheduleNow,
    );
  }

  void _rescheduleNow() {
    if (_days.isEmpty) return;
    // Fire-and-forget, best-effort — a scheduling failure shouldn't
    // surface as an app-breaking error (see [init]).
    _notifications
        .scheduleForDays(
          days: _days,
          notifMode: _notifMode,
          utcOffset: _selectedCity.utcOffset,
          locale: _locale,
          quietHoursEnabled: _quiet,
          includeTahajjud: _tahajjudEnabled,
          prayerLog: _prayerLog,
        )
        .catchError((_) {});
  }

  // City/method/madhab all require a fresh fetch (a cached batch only
  // covers the settings it was fetched under) — so changing any of them
  // without a connection is refused rather than silently left unresolved.
  // Callers should surface [AppLocalizations.errorOfflineSettingsChange]
  // when this returns false.

  Future<bool> selectMadhab(String id) async {
    if (!await _connectivity.hasConnection()) return false;
    _madhab = id;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kMadhab, id));
    return true;
  }

  Future<bool> selectCity(City city) async {
    if (!await _connectivity.hasConnection()) return false;
    _selectedCity = city;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kCityV2, jsonEncode(city.toJson())));
    return true;
  }

  Future<bool> selectMethod(String id) async {
    if (!await _connectivity.hasConnection()) return false;
    _method = id;
    notifyListeners();
    loadPrayerTimes();
    _save((p) => p.setString(_kMethod, id));
    return true;
  }

  void setNotifMode(String key, NotifMode mode) {
    _notifMode[key] = mode;
    notifyListeners();
    _reschedule();
    _save((p) => p.setString('$_kNotifPrefix$key', mode.name));
  }

  void toggleQuiet() {
    _quiet = !_quiet;
    notifyListeners();
    _save((p) => p.setBool(_kQuiet, _quiet));
    _reschedule();
  }

  // Tahajjud (last-third-of-the-night prayer): an opt-in extra row on the
  // home screen, rather than one of the five always-scheduled prayers —
  // most users don't pray it nightly. Its own notification mode lives in
  // [_notifMode] under the 'tahajjud' key, same as the other five.
  void toggleTahajjud() {
    _tahajjudEnabled = !_tahajjudEnabled;
    notifyListeners();
    _save((p) => p.setBool(_kTahajjudEnabled, _tahajjudEnabled));
    _reschedule();
  }

  void completeOnboarding() {
    if (_onboardingDone) return;
    _onboardingDone = true;
    notifyListeners();
    final installedAt = _installedAtMs;
    _save((p) async {
      await p.setBool(_kOnboardingDone, true);
      if (installedAt != null) await p.setInt(_kOnboardingInstall, installedAt);
    });
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _save((p) => p.setString(_kThemeMode, mode.name));
    // The home-screen widget follows this setting too, rather than the
    // phone's own dark mode — see HomeWidgetBridge.
    _syncHomeWidget();
  }

  void setLocale(AppLocale locale) {
    _locale = locale;
    notifyListeners();
    _save((p) => p.setString(_kLocale, locale.name));
    // Scheduled-notification titles are built eagerly (see [_t]'s doc
    // comment) — refresh them so they pick up the new language too, not
    // just the UI. The widget's payload carries pre-translated strings for
    // the same reason.
    _reschedule();
    _syncHomeWidget();
  }

  void toggleFavoriteName(int number) {
    if (!_favoriteNames.remove(number)) _favoriteNames.add(number);
    notifyListeners();
    _save(
      (p) => p.setStringList(
        _kFavoriteNames,
        _favoriteNames.map((n) => n.toString()).toList(),
      ),
    );
  }

  static Map<String, Map<String, PrayerLogStatus>> _decodeLog(String? raw) {
    final log = <String, Map<String, PrayerLogStatus>>{};
    if (raw == null) return log;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final dayEntry in decoded.entries) {
        final day = <String, PrayerLogStatus>{};
        for (final prayerEntry
            in (dayEntry.value as Map<String, dynamic>).entries) {
          final status = PrayerLogStatus.fromName(prayerEntry.value as String);
          if (status != null) day[prayerEntry.key] = status;
        }
        if (day.isNotEmpty) log[dayEntry.key] = day;
      }
    } catch (_) {
      // Ignored — corrupt/unreadable log starts fresh rather than crashing.
    }
    return log;
  }

  /// Re-reads the log from disk, for marks this object didn't make itself —
  /// the home-screen widget's "prayed" button (see [_lifecycle]). Rebuilds
  /// the notification schedule too, so a prayer marked out there stops its
  /// pending end-of-window reminder as well.
  Future<void> _reloadPrayerLog() async {
    final prefs = await SharedPreferences.getInstance();
    // shared_preferences caches everything in Dart, and the widget's write
    // bypassed that cache entirely.
    await prefs.reload();
    final fresh = _decodeLog(prefs.getString(kPrayerLogPrefsKey));
    if (_sameLog(fresh, _prayerLog)) return;
    _prayerLog
      ..clear()
      ..addAll(fresh);
    notifyListeners();
    _reschedule();
  }

  static bool _sameLog(
    Map<String, Map<String, PrayerLogStatus>> a,
    Map<String, Map<String, PrayerLogStatus>> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || other.length != entry.value.length) return false;
      for (final prayer in entry.value.entries) {
        if (other[prayer.key] != prayer.value) return false;
      }
    }
    return true;
  }

  void setPrayerStatus(
    DateTime date,
    String prayerKey,
    PrayerLogStatus? status,
  ) {
    final key = _dateKey(date);
    final day = _prayerLog.putIfAbsent(key, () => {});
    if (status == null || day[prayerKey] == status) {
      day.remove(prayerKey);
    } else {
      day[prayerKey] = status;
    }
    final marked = day.containsKey(prayerKey);
    if (day.isEmpty) _prayerLog.remove(key);
    // A prayer that's now marked has nothing left to be reminded about, so
    // its pending "window is closing" nudge is dropped on the spot (see
    // NotificationService.cancelPrayerEndReminder). Un-marking one instead
    // has to put that reminder back, which only a full reschedule knows how
    // to do — it's the rarer path, so it can afford the extra work.
    if (marked) {
      _notifications
          .cancelPrayerEndReminder(date, prayerKey)
          .catchError((_) {});
    } else {
      _reschedule();
    }
    notifyListeners();
    // The widget reads the log straight from disk rather than from this
    // object, so it's told to redraw only once that write has landed.
    _save(
      (p) => p.setString(
        kPrayerLogPrefsKey,
        jsonEncode(
          _prayerLog.map(
            (k, v) =>
                MapEntry(k, v.map((pk, status) => MapEntry(pk, status.name))),
          ),
        ),
      ),
    ).then((_) => _homeWidget.refresh()).catchError((_) {});
  }

  String _dateKey(DateTime d) => PrayerLogStore.dateKey(d);

  static ThemeMode _themeModeFromName(String? name) => ThemeMode.values
      .firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

  Future<void> _save(Future<void> Function(SharedPreferences) write) async {
    final prefs = await SharedPreferences.getInstance();
    await write(prefs);
  }
}
