import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/day_completion.dart';
import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../models/end_reminders.dart';
import '../models/notif_sound.dart';
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
const _kNotifPrefix = 'notif_';
const _kEndReminders = 'end_reminders';
const _kEndRemindersOff = 'end_reminders_off';
const _kSoundShared = 'sound_shared';
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

  /// Completes once the notification plugin has been initialized — see
  /// [init] and [_rescheduleNow].
  Future<void> _notificationsReady = Future.value();

  String _method = 'uzbekistan';
  String _madhab = 'hanafi';
  City _selectedCity = ReferenceData.cities.firstWhere(
    (c) => c.id == 'tashkent',
  );
  ThemeMode _themeMode = ThemeMode.system;
  AppLocale _locale = AppLocale.ru;
  final Set<int> _favoriteNames = {};
  bool _tahajjudEnabled = false;

  bool _onboardingDone = false;
  bool _restored = false;
  bool _notificationsAllowed = true;

  final Map<String, Map<String, PrayerLogStatus>> _prayerLog = {};

  final Map<String, NotifMode> _notifMode = {
    'tahajjud': NotifMode.notification,
    'fajr': NotifMode.notification,
    'zuhr': NotifMode.notification,
    'asr': NotifMode.notification,
    'maghrib': NotifMode.notification,
    'isha': NotifMode.notification,
  };

  /// Each prayer's "window is closing" reminders, as minutes before the
  /// end, kept the way [normalizeEndReminders] leaves them. Tahajjud has
  /// none — it isn't on the prayer log, so there's no "not marked yet" to
  /// remind about.
  final Map<String, List<int>> _endReminders = {
    for (final key in requiredPrayerKeys) key: [...kDefaultEndReminders],
  };

  /// Reminders switched off for a single day (see
  /// [toggleEndReminderOffToday]), by prayer: the leads in [_endReminders]
  /// that day's prayers get no reminder at. Only one day is ever kept —
  /// switching one off on a new day drops the last day's.
  String? _endRemindersOffDate;
  final Map<String, Set<int>> _endRemindersOff = {};

  /// The sound every notification plays with.
  NotifSound _sharedSound = const NotifSound.phoneDefault();

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
  late final Set<int> favoriteNames = UnmodifiableSetView(_favoriteNames);
  bool isFavoriteName(int number) => _favoriteNames.contains(number);

  // Views rather than copies: the calendar asks for a log per day cell and
  // the settings screens for the notification modes on every rebuild, and
  // `Map.unmodifiable` allocated a fresh map each time. A view is read-only
  // all the same, and everything reading one rebuilds on notifyListeners
  // anyway.
  Map<String, PrayerLogStatus> prayerLogFor(DateTime date) {
    final day = _prayerLog[_dateKey(date)];
    return day == null ? const {} : UnmodifiableMapView(day);
  }

  PrayerLogStatus? prayerStatusFor(DateTime date, String prayerKey) =>
      _prayerLog[_dateKey(date)]?[prayerKey];
  late final Map<String, NotifMode> notifMode = UnmodifiableMapView(_notifMode);
  NotificationService get notifications => _notifications;

  /// [prayerKey]'s reminders before its window closes, in minutes — the
  /// earliest (longest lead) first.
  List<int> endRemindersFor(String prayerKey) =>
      UnmodifiableListView(_endReminders[prayerKey] ?? const []);

  NotifSound get sharedSound => _sharedSound;

  /// Whether the reminder [minutes] before [prayerKey]'s end is switched off
  /// for today's prayer.
  bool isEndReminderOffToday(String prayerKey, int minutes) =>
      _endRemindersOffDate == _dateKey(cityNow) &&
      (_endRemindersOff[prayerKey]?.contains(minutes) ?? false);

  /// The longest lead a reminder for [prayerKey] can have — see
  /// [maxEndReminderLead].
  int maxEndReminderLeadFor(String prayerKey) =>
      maxEndReminderLead(_days, prayerKey);

  /// Whether the phone lets this app's notifications through. Without that
  /// the per-prayer modes read as off and can't be changed (see
  /// NotifModeSelector) — "with sound" means nothing when nothing is shown
  /// at all. The chosen modes themselves are kept, and come back as they
  /// were once notifications are allowed. Optimistic until the first check
  /// comes back, so nobody who allowed them long ago sees a warning flash.
  bool get notificationsAllowed => _notificationsAllowed;

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
    // Memoized: a single home-screen build asks for this several times over
    // (directly, and again through todayPrayerDay), and each answer walked
    // the whole window. Only a new schedule or a new calendar day can
    // change it.
    if (identical(_todayIndexDays, _days) && _todayIndexDate == today) {
      return _todayIndexCache;
    }
    final resolved = _resolveTodayIndex(today);
    _todayIndexDays = _days;
    _todayIndexDate = today;
    _todayIndexCache = resolved;
    return resolved;
  }

  List<PrayerDay>? _todayIndexDays;
  DateTime? _todayIndexDate;
  int _todayIndexCache = 0;

  int _resolveTodayIndex(DateTime today) {
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
    // Memoized with the instant it can next change, since the calendar asks
    // isDayLocked once per day cell and each answer used to walk the whole
    // day window: the anchor holds until today's Fajr while it still points
    // at yesterday, and until midnight once it has moved on.
    if (identical(_anchorDays, _days) &&
        _anchorValidUntil != null &&
        now.isBefore(_anchorValidUntil!)) {
      return _anchorValue!;
    }

    final calendarToday = DateTime(now.year, now.month, now.day);
    PrayerDay? todayRecord;
    for (final d in _days) {
      if (_isSameDate(d.date, calendarToday)) {
        todayRecord = d;
        break;
      }
    }
    final DateTime anchor;
    final DateTime validUntil;
    final fajr = todayRecord == null
        ? null
        : _utcCombine(todayRecord.date, todayRecord.fajr);
    if (fajr != null && now.isBefore(fajr)) {
      anchor = calendarToday.subtract(const Duration(days: 1));
      validUntil = fajr;
    } else {
      anchor = calendarToday;
      // In the same frame of reference as [cityNow] and [_utcCombine] — the
      // city's wall clock carried on a UTC-flagged DateTime — so the
      // comparison above holds wherever the device itself is.
      validUntil = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));
    }
    _anchorDays = _days;
    _anchorValue = anchor;
    _anchorValidUntil = validUntil;
    return anchor;
  }

  List<PrayerDay>? _anchorDays;
  DateTime? _anchorValue;
  DateTime? _anchorValidUntil;

  /// True once a day is old enough to be judged — strictly before the day
  /// preceding the current prayer-day. The calendar uses it to tell "not
  /// judged yet" (today, or yesterday, which someone may still be filling
  /// in) apart from "judged and missed". It says nothing about whether a
  /// day can still be marked: any past day can, from the calendar.
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

  // Whole months fetched for the monthly prayer-times screen, keyed by
  // `<cacheSignature>|<year>-<month>` so a city/method/madhab change doesn't
  // serve another city's schedule. Backed by the same store the day window
  // uses, so it survives a restart too (see PrayerCacheStore.saveMonth).
  final Map<String, List<PrayerDay>> _monthCache = {};

  /// Every day of [year]/[month], for the monthly prayer-times screen — that
  /// reaches a month either side of today, well past the ±7-day window
  /// [days] keeps.
  ///
  /// Memory, then disk, then the network: a month's times don't change for
  /// the settings they were fetched under, so paging back and forth costs
  /// nothing, reopening the screen on a later run costs nothing, and being
  /// offline only matters for a month never opened before.
  Future<List<PrayerDay>> monthDays(int year, int month) async {
    final key = '$_cacheSignature|$year-$month';
    final cached = _monthCache[key];
    if (cached != null) return cached;

    final stored = await _cache.loadMonth(key);
    if (stored != null && stored.isNotEmpty) {
      _monthCache[key] = stored;
      return stored;
    }

    final result = await _api.fetchMonth(
      city: _selectedCity,
      methodCode: _methodCode,
      school: _school,
      tune: _methodTune,
      year: year,
      month: month,
    );
    final days = result.days..sort((a, b) => a.date.compareTo(b.date));
    _monthCache[key] = days;
    unawaited(_cache.saveMonth(key: key, days: days));
    return days;
  }

  Future<void> init() async {
    await _restore();
    // The home-screen widget writes the prayer log straight to disk, behind
    // this object's own in-memory copy (see HomeWidgetBridge) — so whatever
    // was marked from the widget while the app sat in the background is
    // picked up the moment the app comes back to the foreground.
    // The notification permission is re-read on the same occasion: it's
    // changed in the phone's settings, or in a system prompt, both of which
    // end with the app coming back.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _reloadPrayerLog();
        refreshNotificationsAllowed();
      },
    );
    // Routes the notification's "Прочитал"/"Done" action through the same
    // path the "Мои намазы" screen itself uses, so it updates in-memory
    // state (and notifies listeners) rather than only the disk copy.
    _notifications.onMarkDone = (date, prayerKey) async =>
        setPrayerStatus(date, prayerKey, PrayerLogStatus.onTime);
    // Started, not awaited: initializing the plugin talks to the platform
    // (channel setup, restored-notification callbacks) and used to hold the
    // schedule — cached or fetched — behind it for as long as that took, on
    // the one path where the app is showing a spinner. Only scheduling
    // actually needs the plugin, and that waits on this below.
    _notificationsReady = _notifications
        .init()
        .timeout(const Duration(seconds: 5))
        // Ignored — see doc comment above.
        .catchError((_) {});
    unawaited(refreshNotificationsAllowed());
    await loadPrayerTimes();
  }

  /// Re-reads [notificationsAllowed] from the platform.
  Future<void> refreshNotificationsAllowed() async {
    await _notificationsReady;
    bool? allowed;
    try {
      allowed = await _notifications.areNotificationsAllowed();
    } catch (_) {
      // Unknown stays as it was — see [notificationsAllowed] on why the
      // default is optimistic.
    }
    if (allowed == null || allowed == _notificationsAllowed) return;
    _notificationsAllowed = allowed;
    notifyListeners();
    // iOS refuses to book anything while notifications are off, so
    // whatever was scheduled before has to be booked again now.
    if (allowed) _reschedule();
  }

  /// The "allow" button on the notifications-off notice: asks the system
  /// first, and when that changes nothing — the prompt was refused for good,
  /// or only the prayer channel is blocked — opens the app's notification
  /// settings, the one place left to turn them on. Coming back from there
  /// is picked up by the resume check in [init].
  Future<void> allowNotifications() async {
    try {
      await _notifications.requestNotificationsPermission();
    } catch (_) {
      // Falls through to the settings page below.
    }
    await refreshNotificationsAllowed();
    if (!_notificationsAllowed) await _notifications.openSystemSettings();
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
    _endReminders.addAll(_decodeEndReminders(prefs.getString(_kEndReminders)));
    _restoreEndRemindersOff(prefs.getString(_kEndRemindersOff));
    _restoreSounds(prefs);
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
  /// several changes in a row (three notification modes, reminders,
  /// Tahajjud). Without this each tap paid for the whole rebuild.
  void _reschedule() {
    if (_days.isEmpty) return;
    _rescheduleDebounce?.cancel();
    _rescheduleDebounce = Timer(
      const Duration(milliseconds: 400),
      _rescheduleNow,
    );
  }

  Future<void> _rescheduleNow() async {
    if (_days.isEmpty) return;
    // The plugin is initialized in parallel with the first load (see
    // [init]); on the very first run this is what makes sure the alarms are
    // booked against a ready plugin. Once it has completed, awaiting it is
    // free.
    await _notificationsReady;
    if (_days.isEmpty) return;
    // Fire-and-forget, best-effort — a scheduling failure shouldn't
    // surface as an app-breaking error (see [init]).
    _notifications
        .scheduleForDays(
          days: _days,
          notifMode: _notifMode,
          utcOffset: _selectedCity.utcOffset,
          locale: _locale,
          includeTahajjud: _tahajjudEnabled,
          prayerLog: _prayerLog,
          endReminders: _endReminders,
          endRemindersOff: {?_endRemindersOffDate: _endRemindersOff},
          sounds: {
            for (final key in [..._notifMode.keys, kGeneralSoundKey])
              key: _sharedSound.uri,
          },
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

  /// Adds a reminder [minutes] before [prayerKey]'s window closes, held to
  /// [maxEndReminderLeadFor]. False — and nothing changes — when that
  /// prayer already has one at the same lead, or already has
  /// [kMaxEndReminders].
  bool addEndReminder(String prayerKey, int minutes) {
    minutes = min(minutes, maxEndReminderLeadFor(prayerKey));
    final current = _endReminders[prayerKey] ?? const <int>[];
    if (current.contains(minutes) || current.length >= kMaxEndReminders) {
      return false;
    }
    _setEndReminders(prayerKey, [...current, minutes]);
    return true;
  }

  /// Moves the reminder at [oldMinutes] to [newMinutes]. False when another
  /// reminder of the same prayer is already there.
  bool changeEndReminder(String prayerKey, int oldMinutes, int newMinutes) {
    newMinutes = min(newMinutes, maxEndReminderLeadFor(prayerKey));
    final current = _endReminders[prayerKey] ?? const <int>[];
    if (newMinutes == oldMinutes) return true;
    if (current.contains(newMinutes)) return false;
    // Switched off for today, it stays off under its new lead.
    final off = _endRemindersOff[prayerKey];
    if (off != null && off.remove(oldMinutes)) {
      off.add(newMinutes);
      _saveEndRemindersOff();
    }
    _setEndReminders(prayerKey, [
      for (final m in current) m == oldMinutes ? newMinutes : m,
    ]);
    return true;
  }

  void removeEndReminder(String prayerKey, int minutes) {
    if (_endRemindersOff[prayerKey]?.remove(minutes) ?? false) {
      _saveEndRemindersOff();
    }
    final current = _endReminders[prayerKey] ?? const <int>[];
    _setEndReminders(prayerKey, [
      for (final m in current)
        if (m != minutes) m,
    ]);
  }

  void _setEndReminders(String prayerKey, List<int> minutes) {
    _endReminders[prayerKey] = normalizeEndReminders(minutes);
    notifyListeners();
    _reschedule();
    _save((p) => p.setString(_kEndReminders, jsonEncode(_endReminders)));
  }

  /// Switches the reminder [minutes] before [prayerKey]'s end off for
  /// today's prayer alone, or back on. Tomorrow it's on again by itself.
  void toggleEndReminderOffToday(String prayerKey, int minutes) {
    final today = _dateKey(cityNow);
    if (_endRemindersOffDate != today) {
      _endRemindersOffDate = today;
      _endRemindersOff.clear();
    }
    final off = _endRemindersOff.putIfAbsent(prayerKey, () => {});
    if (!off.remove(minutes)) off.add(minutes);
    notifyListeners();
    _reschedule();
    _saveEndRemindersOff();
  }

  void setSharedSound(NotifSound sound) {
    _sharedSound = sound;
    notifyListeners();
    _reschedule();
    _save((p) => p.setString(_kSoundShared, jsonEncode(sound.toJson())));
  }

  void _restoreSounds(SharedPreferences prefs) {
    try {
      final shared = prefs.getString(_kSoundShared);
      if (shared != null) {
        _sharedSound = NotifSound.fromJson(jsonDecode(shared));
      }
    } catch (_) {
      // Unreadable: the phone's default.
    }
  }

  void _saveEndRemindersOff() {
    final date = _endRemindersOffDate;
    _save(
      (p) => p.setString(
        _kEndRemindersOff,
        jsonEncode({
          'date': date,
          'off': {
            for (final e in _endRemindersOff.entries)
              if (e.value.isNotEmpty) e.key: e.value.toList(),
          },
        }),
      ),
    );
  }

  void _restoreEndRemindersOff(String? raw) {
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final off = decoded['off'] as Map<String, dynamic>;
      _endRemindersOffDate = decoded['date'] as String?;
      _endRemindersOff
        ..clear()
        ..addAll({
          for (final e in off.entries)
            if (e.value is List)
              e.key: (e.value as List).whereType<int>().toSet(),
        });
    } catch (_) {
      // Unreadable: nothing is switched off.
    }
  }

  /// Only the prayers actually stored — one missing (nothing saved yet, or
  /// a prayer added later) keeps its default.
  static Map<String, List<int>> _decodeEndReminders(String? raw) {
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final key in requiredPrayerKeys)
          if (decoded[key] is List)
            key: normalizeEndReminders((decoded[key] as List).whereType<int>()),
      };
    } catch (_) {
      // Unreadable: every prayer keeps its default.
      return const {};
    }
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
    // its pending "window is closing" nudges are dropped on the spot (see
    // NotificationService.cancelPrayerEndReminders). Un-marking one instead
    // has to put them back, which only a full reschedule knows how to do —
    // it's the rarer path, so it can afford the extra work.
    if (marked) {
      _notifications
          .cancelPrayerEndReminders(date, prayerKey)
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
