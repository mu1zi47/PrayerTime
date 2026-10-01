import '../models/prayer_day.dart';

/// City-local wall-clock start of [key]'s window on [day] — the prayer's own
/// time. Encoded the way AppState.cityNow is: a UTC-flagged DateTime whose
/// fields are the city's local time.
DateTime prayerWindowStart(PrayerDay day, String key) =>
    _combine(day.date, switch (key) {
      'tahajjud' => day.tahajjud,
      'fajr' => day.fajr,
      'zuhr' => day.zuhr,
      'asr' => day.asr,
      'maghrib' => day.maghrib,
      'isha' => day.isha,
      _ => day.fajr,
    });

/// City-local wall-clock end of [key]'s window on `days[index]` — where the
/// next prayer starts (Fajr's at sunrise, Isha's at the following day's
/// Fajr). Null when that can't be known: the last entry in [days] has no
/// following day to end its Isha.
DateTime? prayerWindowEnd(List<PrayerDay> days, int index, String key) {
  final day = days[index];
  switch (key) {
    case 'fajr':
      return _combine(day.date, day.sunrise);
    case 'zuhr':
      return _combine(day.date, day.asr);
    case 'asr':
      return _combine(day.date, day.maghrib);
    case 'maghrib':
      return _combine(day.date, day.isha);
    case 'isha':
      if (index + 1 >= days.length) return null;
      final next = days[index + 1];
      return _combine(next.date, next.fajr);
    default:
      return null;
  }
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

/// "06:05" — a wall-clock time the way the app shows prayer times.
String formatClock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
