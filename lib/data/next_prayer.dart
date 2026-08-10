import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../widgets/prayer_icon.dart';

class NextPrayerInfo {
  final PrayerKind kind;
  final String time;
  final Duration remaining;

  const NextPrayerInfo({required this.kind, required this.time, required this.remaining});

  String countdownLabel(AppLocalizations t) => _formatCountdown(t, remaining);
}

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
      return NextPrayerInfo(kind: kind, time: time, remaining: dt.difference(cityNow));
    }
  }

  if (days.length > 1) {
    final tomorrow = days[1];
    final dt = _combine(tomorrow.date, tomorrow.fajr);
    return NextPrayerInfo(
      kind: PrayerKind.fajr,
      time: tomorrow.fajr,
      remaining: dt.difference(cityNow),
    );
  }

  return null;
}

/// Sunrise is included here (unlike [computeNextPrayer]'s list) so Fajr's
/// "current" window correctly ends there — without it, the whole
/// sunrise-to-Zuhr stretch (when no prayer is actually active) still read
/// as "current: Fajr".
PrayerKind? computeCurrentPrayer(List<PrayerDay> days, DateTime cityNow) {
  if (days.isEmpty) return null;

  final today = days.first;
  final ordered = [
    (PrayerKind.fajr, today.fajr),
    (PrayerKind.sunrise, today.sunrise),
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

bool hasPrayerTimePassed(PrayerDay day, PrayerKind kind, DateTime cityNow) {
  final time = switch (kind) {
    PrayerKind.fajr => day.fajr,
    PrayerKind.sunrise => day.sunrise,
    PrayerKind.zuhr => day.zuhr,
    PrayerKind.asr => day.asr,
    PrayerKind.maghrib => day.maghrib,
    PrayerKind.isha => day.isha,
  };
  return !_combine(day.date, time).isAfter(cityNow);
}

DateTime _combine(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime.utc(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}

String _formatCountdown(AppLocalizations t, Duration d) {
  final totalMinutes = d.inMinutes < 0 ? 0 : d.inMinutes;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return t.countdownMinutesOnly(m);
  if (m == 0) return t.countdownHoursOnly(h);
  return t.countdownHoursMinutes(h, m);
}
