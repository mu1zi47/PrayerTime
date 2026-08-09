import '../models/prayer_day.dart';
import '../widgets/prayer_icon.dart';

class NextPrayerInfo {
  final PrayerKind kind;
  final String time;
  final String countdownLabel;

  const NextPrayerInfo({required this.kind, required this.time, required this.countdownLabel});
}

/// Finds the next upcoming prayer (Fajr/Zuhr/Asr/Maghrib/Isha — Sunrise
/// isn't a prayer) relative to [cityNow], the current wall-clock time in
/// the schedule's city. Wraps to tomorrow's Fajr if today's are all past.
/// Returns null if [days] doesn't have enough data yet.
NextPrayerInfo? computeNextPrayer(List<PrayerDay> days, DateTime cityNow) {
  if (days.isEmpty) return null;

  final today = days.first;
  final ordered = [
    (PrayerKind.fajr, today.fajr),
    (PrayerKind.zuhr, today.zuhr),
    (PrayerKind.asr, today.asr),
    (PrayerKind.maghrib, today.maghrib),
    (PrayerKind.isha, today.isha),
  ];

  for (final (kind, time) in ordered) {
    final dt = _combine(today.date, time);
    if (dt.isAfter(cityNow)) {
      return NextPrayerInfo(kind: kind, time: time, countdownLabel: _formatCountdown(dt.difference(cityNow)));
    }
  }

  if (days.length > 1) {
    final tomorrow = days[1];
    final dt = _combine(tomorrow.date, tomorrow.fajr);
    return NextPrayerInfo(
      kind: PrayerKind.fajr,
      time: tomorrow.fajr,
      countdownLabel: _formatCountdown(dt.difference(cityNow)),
    );
  }

  return null;
}

/// Finds the prayer currently "in effect" — the last of today's prayers
/// (Fajr/Zuhr/Asr/Maghrib/Isha) whose time has already passed relative to
/// [cityNow]. Returns null before today's Fajr (yesterday's Isha isn't in
/// [days], so there's nothing to point at yet).
PrayerKind? computeCurrentPrayer(List<PrayerDay> days, DateTime cityNow) {
  if (days.isEmpty) return null;

  final today = days.first;
  final ordered = [
    (PrayerKind.fajr, today.fajr),
    (PrayerKind.zuhr, today.zuhr),
    (PrayerKind.asr, today.asr),
    (PrayerKind.maghrib, today.maghrib),
    (PrayerKind.isha, today.isha),
  ];

  PrayerKind? current;
  for (final (kind, time) in ordered) {
    final dt = _combine(today.date, time);
    if (dt.isAfter(cityNow)) break;
    current = kind;
  }
  return current;
}

/// Builds a DateTime whose UTC-read fields are exactly (date, hh:mm) — no
/// device-timezone involved. Must use `DateTime.utc`, not the local
/// `DateTime()` constructor: [cityNow] is itself a UTC-flagged "fake"
/// instant (see [AppState.cityNow]) encoding the *city's* wall clock, not
/// the device's. Comparing it against a device-local-constructed DateTime
/// would silently mix in the device's own timezone offset and produce a
/// wrong comparison whenever the device isn't in UTC.
DateTime _combine(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime.utc(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}

String _formatCountdown(Duration d) {
  final totalMinutes = d.inMinutes < 0 ? 0 : d.inMinutes;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return 'через $m мин';
  if (m == 0) return 'через $h ч';
  return 'через $h ч $m мин';
}
