import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_log_status.dart';

/// The shared_preferences key backing the prayer log — kept in sync with
/// AppState, which reads/writes the same key for its in-memory copy. Public
/// (unlike everything else in AppState) because the "mark as done" action
/// on a prayer-time notification writes here directly, without going
/// through AppState — that write can happen in a background isolate with
/// no running AppState instance at all (see NotificationService's
/// background response handler).
const kPrayerLogPrefsKey = 'prayer_log';

/// Reads/writes the prayer log's on-disk format directly — the single
/// source of truth for that format, shared by AppState (in-process,
/// notifyListeners-backed) and this store (works from any isolate).
class PrayerLogStore {
  PrayerLogStore._();

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Marks [prayerKey] on [dateKey] as prayed on time — used by the
  /// notification action button, which can fire with the app fully
  /// terminated (no AppState to route this through).
  static Future<void> markOnTime(String dateKey, String prayerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPrayerLogPrefsKey);

    var decoded = <String, dynamic>{};
    if (raw != null) {
      try {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Ignored — corrupt/unreadable log starts fresh rather than
        // throwing away this write.
      }
    }

    final day = Map<String, dynamic>.from(decoded[dateKey] as Map? ?? const {});
    day[prayerKey] = PrayerLogStatus.onTime.name;
    decoded[dateKey] = day;

    await prefs.setString(kPrayerLogPrefsKey, jsonEncode(decoded));
  }
}
