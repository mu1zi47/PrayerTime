enum PrayerLogStatus {
  onTime,
  qada;

  static PrayerLogStatus? fromName(String? name) {
    for (final s in PrayerLogStatus.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}
