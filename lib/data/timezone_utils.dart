import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

/// Resolves a city's current UTC offset from its IANA time zone name (e.g.
/// "Asia/Tashkent"), including DST where applicable. Self-initializes the tz
/// database on first use so callers don't need to sequence around
/// [NotificationService.init] — safe to call before it, and idempotent.
Duration utcOffsetForTimeZone(String ianaName) {
  if (ianaName.isEmpty) return Duration.zero;
  if (!_initialized) {
    tz_data.initializeTimeZones();
    _initialized = true;
  }
  try {
    final location = tz.getLocation(ianaName);
    return tz.TZDateTime.now(location).timeZoneOffset;
  } catch (_) {
    return Duration.zero;
  }
}
