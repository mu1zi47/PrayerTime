import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

/// Loads the tz database once per process. Everything that needs it goes
/// through here rather than calling `initializeTimeZones` itself —
/// [NotificationService.init] used to call it separately, which parsed the
/// whole database a second time on startup.
///
/// The `latest_10y` build carries the same zones as `latest_all` with the
/// historical transitions trimmed to a ten-year window. Nothing here ever
/// asks about a past decade — only the offset in effect right now — so the
/// rest was pure startup cost and resident memory.
void ensureTimeZonesInitialized() {
  if (_initialized) return;
  tz_data.initializeTimeZones();
  _initialized = true;
}

class _CachedOffset {
  final Duration offset;

  /// Offsets only ever change on an hour boundary (a DST transition), so a
  /// cache entry stays good until the current hour is over.
  final DateTime validUntil;

  const _CachedOffset(this.offset, this.validUntil);
}

final _offsetCache = <String, _CachedOffset>{};

/// Resolves a city's current UTC offset from its IANA time zone name (e.g.
/// "Asia/Tashkent"), including DST where applicable.
///
/// Memoized because this sits on a hot path: `AppState.cityNow` calls it,
/// and that getter runs many times per frame (every `todayIndex`, every
/// prayer-day lookup, every countdown). Each miss costs a zone lookup plus
/// a `TZDateTime.now`.
Duration utcOffsetForTimeZone(String ianaName) {
  if (ianaName.isEmpty) return Duration.zero;

  final now = DateTime.now();
  final cached = _offsetCache[ianaName];
  if (cached != null && now.isBefore(cached.validUntil)) return cached.offset;

  ensureTimeZonesInitialized();
  Duration offset;
  try {
    final location = tz.getLocation(ianaName);
    offset = tz.TZDateTime.now(location).timeZoneOffset;
  } catch (_) {
    offset = Duration.zero;
  }
  _offsetCache[ianaName] = _CachedOffset(
    offset,
    DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(const Duration(hours: 1)),
  );
  return offset;
}
