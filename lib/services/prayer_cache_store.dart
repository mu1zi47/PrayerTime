import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_day.dart';

const _kCacheSignature = 'prayer_cache_signature';
const _kCacheDays = 'prayer_cache_days';

/// Persists the last successfully fetched batch of [PrayerDay]s so they can
/// still be shown when a later launch has no internet connection — see
/// [AppState.loadPrayerTimes]. Keyed by a "signature" of the settings that
/// affect the fetch (city + method + madhab), so a cached batch is only ever
/// served back for the exact settings it was fetched under.
class PrayerCacheStore {
  const PrayerCacheStore();

  /// City id + method + madhab — the inputs that determine what a fetch
  /// returns. Tahajjud isn't included: it's already part of every fetched
  /// day (the "Lastthird" timing) and toggling it doesn't refetch anything.
  static String signatureFor({
    required String cityId,
    required String method,
    required String madhab,
  }) => '$cityId|$method|$madhab';

  Future<void> save({
    required String signature,
    required List<PrayerDay> days,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCacheSignature, signature);
    await prefs.setString(
      _kCacheDays,
      jsonEncode(days.map(_toJson).toList()),
    );
  }

  /// Returns the cached days for [signature], or null if nothing is cached
  /// or the cache was saved under different settings.
  Future<List<PrayerDay>?> load(String signature) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kCacheSignature) != signature) return null;
    final raw = prefs.getString(_kCacheDays);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  /// Whole months kept for the monthly prayer-times screen, keyed by
  /// `<signature>|<year>-<month>` (see [AppState.monthDays]).
  ///
  /// A month's times never change for a given city/method/madhab, so a
  /// stored month is served as-is: reopening the screen — or opening it with
  /// no connection at all — costs nothing after the first fetch. Only the
  /// handful of months the screen can reach is kept, oldest write dropped
  /// first.
  static const _kMonths = 'prayer_month_cache';
  static const _maxStoredMonths = 4;

  Future<List<PrayerDay>?> loadMonth(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMonths);
    if (raw == null) return null;
    try {
      final stored = jsonDecode(raw) as Map<String, dynamic>;
      final days = stored[key] as List?;
      if (days == null) return null;
      return days.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMonth({
    required String key,
    required List<PrayerDay> days,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var stored = <String, dynamic>{};
    final raw = prefs.getString(_kMonths);
    if (raw != null) {
      try {
        stored = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {
        // Ignored — an unreadable blob is simply replaced.
      }
    }
    // Re-inserted rather than updated in place, so the JSON map's own order
    // is oldest-write-first and the trim below drops the stalest entry.
    stored.remove(key);
    stored[key] = days.map(_toJson).toList();
    while (stored.length > _maxStoredMonths) {
      stored.remove(stored.keys.first);
    }
    await prefs.setString(_kMonths, jsonEncode(stored));
  }

  static Map<String, dynamic> _toJson(PrayerDay d) => {
    'date': d.date.toIso8601String(),
    'fajr': d.fajr,
    'sunrise': d.sunrise,
    'zuhr': d.zuhr,
    'asr': d.asr,
    'maghrib': d.maghrib,
    'isha': d.isha,
    'tahajjud': d.tahajjud,
  };

  static PrayerDay _fromJson(Map<String, dynamic> j) => PrayerDay(
    date: DateTime.parse(j['date'] as String),
    fajr: j['fajr'] as String,
    sunrise: j['sunrise'] as String,
    zuhr: j['zuhr'] as String,
    asr: j['asr'] as String,
    maghrib: j['maghrib'] as String,
    isha: j['isha'] as String,
    tahajjud: j['tahajjud'] as String,
  );
}
