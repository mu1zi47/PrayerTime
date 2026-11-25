import '../models/prayer_log_status.dart';

/// The five obligatory prayers a day is judged by — Tahajjud is nafl
/// (optional) and sunrise isn't a prayer at all, so neither counts toward
/// completion.
const requiredPrayerKeys = ['fajr', 'zuhr', 'asr', 'maghrib', 'isha'];

/// How a single day reads on the calendar (see PrayerCalendarScreen).
enum DayCompletion {
  /// All five prayers are marked as read.
  onTime,

  /// Locked (its edit window has closed, see AppState.isDayLocked) and
  /// still not fully marked — a real miss.
  missed,

  /// Still editable or hasn't started yet — nothing to judge yet.
  upcoming,
}

/// [isLocked] should come from `AppState.isDayLocked` — a day that's still
/// editable (today, or yesterday within its grace window) or fully in the
/// future reads as [DayCompletion.upcoming] rather than [DayCompletion.missed]
/// even if nothing (or not everything) is marked yet.
DayCompletion classifyDay(
  Map<String, PrayerLogStatus> dayLog, {
  required bool isLocked,
}) {
  final fullyMarked = requiredPrayerKeys.every(dayLog.containsKey);
  if (fullyMarked) return DayCompletion.onTime;
  return isLocked ? DayCompletion.missed : DayCompletion.upcoming;
}
