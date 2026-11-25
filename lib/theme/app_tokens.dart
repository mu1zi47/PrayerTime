/// Shared layout scale. Screen gutters stay independent of component padding.
abstract final class AppSpacing {
  static const none = 0.0;
  static const micro = 2.0;
  static const xxs = 4.0;
  static const compact = 6.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const screen = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const huge = 64.0;
}

/// Use the same size for the same text role on every screen.
abstract final class AppFontSize {
  static const caption = 11.0;
  static const small = 12.0;
  static const body = 14.0;
  static const bodyLarge = 16.0;
  static const title = 18.0;
  static const heading = 22.0;
  static const display = 28.0;
  static const timer = 32.0;
  static const hero = 40.0;
  static const counter = 64.0;
}

abstract final class AppIconSize {
  static const small = 16.0;
  static const medium = 20.0;
  static const action = 22.0;
  static const large = 24.0;
  static const display = 32.0;
  static const hero = 40.0;
  static const oversized = 48.0;
}

/// Fixed geometry for recurring controls, independently of spacing.
abstract final class AppSize {
  static const badge = 32.0;
  static const largeBadge = 40.0;
  static const touchTarget = 48.0;
  static const prayerRow = touchTarget + AppSpacing.xxs * 2;
  static const shortcut = 140.0;
  static const mapPreview = 128.0;
  static const nearbyCard = 200.0;
  static const sheetHandleWidth = 36.0;
  static const sheetHandleHeight = 4.0;
}

abstract final class AppOpacity {
  static const faint = .04;
  static const border = .08;
  static const tint = .12;
  static const disabled = .36;
  static const secondary = .56;
  static const strong = .78;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 220);
}
