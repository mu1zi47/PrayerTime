import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../widgets/prayer_icon.dart';

class NextPrayerInfo {
  final PrayerKind kind;
  final String time;

  /// The calendar date this time belongs to — lets the UI tell "later
  /// today" apart from "tomorrow" (see HomeScreen's "Завтра" labeling).
  final DateTime date;

  final Duration remaining;

  const NextPrayerInfo({
    required this.kind,
    required this.time,
    required this.date,
    required this.remaining,
  });

  String countdownLabel(AppLocalizations t) => _formatCountdown(t, remaining);
}

class CurrentPrayerInfo {
  final PrayerKind kind;
  final String time;

  /// The calendar date this time belongs to.
  final DateTime date;

  /// True when this is yesterday's Isha carried over past midnight (see
  /// [computeCurrentPrayer]) rather than something from today's own
  /// schedule — the UI needs this to avoid highlighting today's own
  /// (not-yet-happened) Isha row instead, and to label the "Вчера" card.
  final bool isFromPreviousDay;

  const CurrentPrayerInfo({
    required this.kind,
    required this.time,
    required this.date,
    this.isFromPreviousDay = false,
  });
}

NextPrayerInfo? computeNextPrayer(
  List<PrayerDay> days,
  DateTime cityNow, {
  bool includeTahajjud = false,
  int todayIndex = 0,
}) {
  if (todayIndex < 0 || todayIndex >= days.length) return null;

  final today = days[todayIndex];
  final ordered = [
    if (includeTahajjud) (PrayerKind.tahajjud, today.tahajjud),
    (PrayerKind.fajr, today.fajr),
    (PrayerKind.zuhr, today.zuhr),
    (PrayerKind.asr, today.asr),
    (PrayerKind.maghrib, today.maghrib),
    (PrayerKind.isha, today.isha),
  ];

  for (final (kind, time) in ordered) {
    final dt = _combine(today.date, time);
    if (dt.isAfter(cityNow)) {
      return NextPrayerInfo(
        kind: kind,
        time: time,
        date: today.date,
        remaining: dt.difference(cityNow),
      );
    }
  }

  if (todayIndex + 1 < days.length) {
    final tomorrow = days[todayIndex + 1];
    // Same precedence as `ordered` above — Tahajjud (when enabled) still
    // comes before Fajr even across the day boundary, since it's earlier in
    // the clock on tomorrow's own night too.
    final (kind, time) = includeTahajjud
        ? (PrayerKind.tahajjud, tomorrow.tahajjud)
        : (PrayerKind.fajr, tomorrow.fajr);
    final dt = _combine(tomorrow.date, time);
    return NextPrayerInfo(
      kind: kind,
      time: time,
      date: tomorrow.date,
      remaining: dt.difference(cityNow),
    );
  }

  return null;
}

/// Sunrise is included here (unlike [computeNextPrayer]'s list) so Fajr's
/// "current" window correctly ends there — without it, the whole
/// sunrise-to-Zuhr stretch (when no prayer is actually active) still read
/// as "current: Fajr".
CurrentPrayerInfo? computeCurrentPrayer(
  List<PrayerDay> days,
  DateTime cityNow, {
  bool includeTahajjud = false,
  int todayIndex = 0,
}) {
  if (todayIndex < 0 || todayIndex >= days.length) return null;

  final today = days[todayIndex];
  final ordered = [
    if (includeTahajjud) (PrayerKind.tahajjud, today.tahajjud),
    (PrayerKind.fajr, today.fajr),
    (PrayerKind.sunrise, today.sunrise),
    (PrayerKind.zuhr, today.zuhr),
    (PrayerKind.asr, today.asr),
    (PrayerKind.maghrib, today.maghrib),
    (PrayerKind.isha, today.isha),
  ];

  (PrayerKind, String)? current;
  for (final (kind, time) in ordered) {
    final dt = _combine(today.date, time);
    if (dt.isAfter(cityNow)) break;
    current = (kind, time);
  }
  if (current != null) {
    return CurrentPrayerInfo(
      kind: current.$1,
      time: current.$2,
      date: today.date,
    );
  }

  // None of today's own times have arrived yet — cityNow is in the gap
  // between midnight and today's Tahajjud/Fajr. Isha (from the day before,
  // at todayIndex - 1) is still "current" through that whole gap; without a
  // previous day in [days] to fall back on there's nothing to say it's
  // still ongoing, so it reads as "no current prayer" instead.
  if (todayIndex == 0) return null;
  final yesterday = days[todayIndex - 1];
  return CurrentPrayerInfo(
    kind: PrayerKind.isha,
    time: yesterday.isha,
    date: yesterday.date,
    isFromPreviousDay: true,
  );
}

bool hasPrayerTimePassed(PrayerDay day, PrayerKind kind, DateTime cityNow) {
  final time = switch (kind) {
    PrayerKind.tahajjud => day.tahajjud,
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
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

String _formatCountdown(AppLocalizations t, Duration d) {
  final totalMinutes = d.inMinutes < 0 ? 0 : d.inMinutes;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return t.countdownMinutesOnly(m);
  if (m == 0) return t.countdownHoursOnly(h);
  return t.countdownHoursMinutes(h, m);
}
