import '../data/prayer_window.dart';
import '../l10n/app_localizations.dart';
import 'prayer_day.dart';

/// The "window is closing" reminders each prayer gets until someone sets
/// their own: one, half an hour before the end — all the app used to offer.
const kDefaultEndReminders = [30];

/// How many a single prayer can have. Kept small on purpose: every one is
/// booked for each of the days on hand, and Samsung's One UI refuses an app
/// more than 500 pending alarms — 5 prayers × 5 × 8 days stays well under.
const kMaxEndReminders = 5;

/// The shortest and longest lead the picker offers, and the step between.
/// Five minutes is about the least that still leaves time to pray; nearly
/// six hours already covers all of Isha's window but its very start.
const kMinEndReminderMinutes = 5;
const kMaxEndReminderMinutes = 5 * 60 + 55;
const kEndReminderStep = 5;

/// The longest lead [prayerKey] can be given: its shortest window among
/// [days] — windows shift from day to day, and a lead has to fit every one
/// it's booked on — rounded down to a whole step. With no times on hand
/// yet, just the picker's own limit.
int maxEndReminderLead(List<PrayerDay> days, String prayerKey) {
  int? shortest;
  for (var i = 0; i < days.length; i++) {
    final end = prayerWindowEnd(days, i, prayerKey);
    if (end == null) continue;
    final length = end
        .difference(prayerWindowStart(days[i], prayerKey))
        .inMinutes;
    if (shortest == null || length < shortest) shortest = length;
  }
  if (shortest == null) return kMaxEndReminderMinutes;
  final lead = shortest ~/ kEndReminderStep * kEndReminderStep;
  return lead.clamp(kMinEndReminderMinutes, kMaxEndReminderMinutes);
}

/// A list as it's kept: no repeats, nothing out of range, at most
/// [kMaxEndReminders], earliest reminder (longest lead) first.
List<int> normalizeEndReminders(Iterable<int> minutes) {
  final unique =
      minutes
          .where(
            (m) => m >= kMinEndReminderMinutes && m <= kMaxEndReminderMinutes,
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  return unique.take(kMaxEndReminders).toList();
}

/// "30 мин", "1 ч", "1 ч 30 мин" — how a lead reads everywhere it's shown,
/// the notification itself included.
String formatLeadTime(AppLocalizations t, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return t.durationMinutes(m);
  if (m == 0) return t.durationHours(h);
  return t.durationHoursMinutes(h, m);
}
