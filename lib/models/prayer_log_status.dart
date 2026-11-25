enum PrayerLogStatus {
  onTime;

  // Keep reading existing widget values and legacy late marks without loss.
  static PrayerLogStatus? fromName(String? name) => switch (name) {
    'onTime' || 'qada' => onTime,
    _ => null,
  };
}
