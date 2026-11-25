import 'package:flutter/material.dart';

class AppPalette {
  final Color controlFill;
  final Color onControlFill;
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;

  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;

  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent400;
  final Color accent500;
  final Color accent600;
  final Color accent700;
  final Color accent800;
  final Color accent900;

  final Color accent2_100;
  final Color accent2_200;
  final Color accent2_300;
  final Color accent2_400;
  final Color accent2_500;
  final Color accent2_600;
  final Color accent2_700;
  final Color accent2_800;
  final Color accent2_900;

  const AppPalette({
    required this.controlFill,
    required this.onControlFill,
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent500,
    required this.accent600,
    required this.accent700,
    required this.accent800,
    required this.accent900,
    required this.accent2_100,
    required this.accent2_200,
    required this.accent2_300,
    required this.accent2_400,
    required this.accent2_500,
    required this.accent2_600,
    required this.accent2_700,
    required this.accent2_800,
    required this.accent2_900,
  });

  static AppPalette lerp(AppPalette a, AppPalette b, double t) => AppPalette(
    controlFill: Color.lerp(a.controlFill, b.controlFill, t)!,
    onControlFill: Color.lerp(a.onControlFill, b.onControlFill, t)!,
    bg: Color.lerp(a.bg, b.bg, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    text: Color.lerp(a.text, b.text, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    accent2: Color.lerp(a.accent2, b.accent2, t)!,
    neutral100: Color.lerp(a.neutral100, b.neutral100, t)!,
    neutral200: Color.lerp(a.neutral200, b.neutral200, t)!,
    neutral300: Color.lerp(a.neutral300, b.neutral300, t)!,
    neutral400: Color.lerp(a.neutral400, b.neutral400, t)!,
    neutral500: Color.lerp(a.neutral500, b.neutral500, t)!,
    neutral600: Color.lerp(a.neutral600, b.neutral600, t)!,
    neutral700: Color.lerp(a.neutral700, b.neutral700, t)!,
    neutral800: Color.lerp(a.neutral800, b.neutral800, t)!,
    neutral900: Color.lerp(a.neutral900, b.neutral900, t)!,
    accent100: Color.lerp(a.accent100, b.accent100, t)!,
    accent200: Color.lerp(a.accent200, b.accent200, t)!,
    accent300: Color.lerp(a.accent300, b.accent300, t)!,
    accent400: Color.lerp(a.accent400, b.accent400, t)!,
    accent500: Color.lerp(a.accent500, b.accent500, t)!,
    accent600: Color.lerp(a.accent600, b.accent600, t)!,
    accent700: Color.lerp(a.accent700, b.accent700, t)!,
    accent800: Color.lerp(a.accent800, b.accent800, t)!,
    accent900: Color.lerp(a.accent900, b.accent900, t)!,
    accent2_100: Color.lerp(a.accent2_100, b.accent2_100, t)!,
    accent2_200: Color.lerp(a.accent2_200, b.accent2_200, t)!,
    accent2_300: Color.lerp(a.accent2_300, b.accent2_300, t)!,
    accent2_400: Color.lerp(a.accent2_400, b.accent2_400, t)!,
    accent2_500: Color.lerp(a.accent2_500, b.accent2_500, t)!,
    accent2_600: Color.lerp(a.accent2_600, b.accent2_600, t)!,
    accent2_700: Color.lerp(a.accent2_700, b.accent2_700, t)!,
    accent2_800: Color.lerp(a.accent2_800, b.accent2_800, t)!,
    accent2_900: Color.lerp(a.accent2_900, b.accent2_900, t)!,
  );

  Color get divider => text.withValues(alpha: 0.16);
}

// Neutral accents in both themes. Dark mode uses white light and controls.
const _light = AppPalette(
  controlFill: Color(0xFF303A4A),
  onControlFill: Color(0xFFFFFFFF),
  bg: Color(0xFFF3F6FB),
  surface: Color(0xFFFFFFFF),
  text: Color(0xFF16213C),
  accent: Color(0xFF26344A),
  accent2: Color(0xFF596579),
  neutral100: Color(0xFFEDF0F9),
  neutral200: Color(0xFFDBE0EE),
  neutral300: Color(0xFFC4CBDC),
  neutral400: Color(0xFFA5ADC0),
  neutral500: Color(0xFF868EA1),
  neutral600: Color(0xFF6A7182),
  neutral700: Color(0xFF505664),
  neutral800: Color(0xFF383C47),
  neutral900: Color(0xFF25282E),
  accent100: Color(0xFFEDF0F5),
  accent200: Color(0xFFDCE1E9),
  accent300: Color(0xFFC4CBD7),
  accent400: Color(0xFFA4AEBD),
  accent500: Color(0xFF828EA0),
  accent600: Color(0xFF626F83),
  accent700: Color(0xFF344157),
  accent800: Color(0xFF253146),
  accent900: Color(0xFF16213C),
  accent2_100: Color(0xFFF0F2F6),
  accent2_200: Color(0xFFE0E5EC),
  accent2_300: Color(0xFFCAD1DD),
  accent2_400: Color(0xFFAFB8C7),
  accent2_500: Color(0xFF8C99AB),
  accent2_600: Color(0xFF6F7D91),
  accent2_700: Color(0xFF536176),
  accent2_800: Color(0xFF39485E),
  accent2_900: Color(0xFF253349),
);

// Mirrors `_light`'s internal logic (the NNN scales run from "closest to
// bg" to "closest to text/most saturated") but with the ramp direction
// flipped, since in dark mode the darkest tone is the background and the
// lightest is the readable-on-dark end.
const _dark = AppPalette(
  controlFill: Color(0xFF303B4D),
  onControlFill: Color(0xFFFFFFFF),
  bg: Color(0xFF0C182C),
  surface: Color(0xFF192943),
  text: Color(0xFFFFFFFF),
  accent: Color(0xFFFFFFFF),
  accent2: Color(0xFFA8B3C5),
  neutral100: Color(0xFF161A21),
  neutral200: Color(0xFF20242C),
  neutral300: Color(0xFF292E3A),
  neutral400: Color(0xFF353C4C),
  neutral500: Color(0xFF495266),
  neutral600: Color(0xFF5D6982),
  neutral700: Color(0xFF7381A0),
  neutral800: Color(0xFF95A3C2),
  neutral900: Color(0xFFC7D0E4),
  accent100: Color(0xFF202B3C),
  accent200: Color(0xFF303C4E),
  accent300: Color(0xFF435068),
  accent400: Color(0xFF5A6980),
  accent500: Color(0xFF7C8BA1),
  accent600: Color(0xFFA8B3C5),
  accent700: Color(0xFFFFFFFF),
  accent800: Color(0xFFFFFFFF),
  accent900: Color(0xFFFFFFFF),
  accent2_100: Color(0xFF202A3A),
  accent2_200: Color(0xFF303B4E),
  accent2_300: Color(0xFF435068),
  accent2_400: Color(0xFF5A6980),
  accent2_500: Color(0xFF7C8BA1),
  accent2_600: Color(0xFF99A6BA),
  accent2_700: Color(0xFFB8C3D3),
  accent2_800: Color(0xFFD7DFEA),
  accent2_900: Color(0xFFEEF2F8),
);

class AppColors {
  AppColors._();

  static const AppPalette lightPalette = _light;
  static const AppPalette darkPalette = _dark;

  static AppPalette _active = _light;

  static void setDark(bool value) => _active = value ? _dark : _light;

  static void setPalette(AppPalette palette) => _active = palette;

  /// Subscribe even const widgets to palette changes.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<AppPaletteScope>();
  }

  /// One selection treatment across prayer rows, pickers, and controls.
  static LinearGradient get selectionGradient => LinearGradient(
    colors: [accent.withValues(alpha: .12), accent.withValues(alpha: .02)],
  );
  static Color get selectionFill => accent.withValues(alpha: .12);
  static Color get controlFill => _active.controlFill;
  static Color get onControlFill => _active.onControlFill;
  static Color get glow => _active.accent;

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);
  static const destructive = Color(0xFFC4523F);
  static const location = Color(0xFF2F80ED);

  static Color get bg => _active.bg;
  static Color get surface => _active.surface;
  static Color get text => _active.text;
  static Color get accent => _active.accent;
  static Color get accent2 => _active.accent2;
  static Color get divider => _active.divider;

  static Color get neutral100 => _active.neutral100;
  static Color get neutral200 => _active.neutral200;
  static Color get neutral300 => _active.neutral300;
  static Color get neutral400 => _active.neutral400;
  static Color get neutral500 => _active.neutral500;
  static Color get neutral600 => _active.neutral600;
  static Color get neutral700 => _active.neutral700;
  static Color get neutral800 => _active.neutral800;
  static Color get neutral900 => _active.neutral900;

  static Color get accent100 => _active.accent100;
  static Color get accent200 => _active.accent200;
  static Color get accent300 => _active.accent300;
  static Color get accent400 => _active.accent400;
  static Color get accent500 => _active.accent500;
  static Color get accent600 => _active.accent600;
  static Color get accent700 => _active.accent700;
  static Color get accent800 => _active.accent800;
  static Color get accent900 => _active.accent900;

  static Color get accent2_100 => _active.accent2_100;
  static Color get accent2_200 => _active.accent2_200;
  static Color get accent2_300 => _active.accent2_300;
  static Color get accent2_400 => _active.accent2_400;
  static Color get accent2_500 => _active.accent2_500;
  static Color get accent2_600 => _active.accent2_600;
  static Color get accent2_700 => _active.accent2_700;
  static Color get accent2_800 => _active.accent2_800;
  static Color get accent2_900 => _active.accent2_900;
}

// Shared corners for controls, inner surfaces, and grouped panels.
class AppRadius {
  AppRadius._();

  static const indicator = 2.0;
  static const inner = 8.0;
  static const sm = 12.0;
  static const md = 12.0;
  static const control = 18.0;
  static const row = 20.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

/// Covers the Navigator too, so sheets and pushed routes recolor together.
class AppPaletteScope extends InheritedNotifier<ValueNotifier<AppPalette>> {
  const AppPaletteScope({
    super.key,
    required ValueNotifier<AppPalette> palette,
    required super.child,
  }) : super(notifier: palette);
}

class AnimatedAppPalette extends StatefulWidget {
  final bool dark;
  final Widget child;

  const AnimatedAppPalette({
    super.key,
    required this.dark,
    required this.child,
  });

  @override
  State<AnimatedAppPalette> createState() => _AnimatedAppPaletteState();
}

class _AnimatedAppPaletteState extends State<AnimatedAppPalette>
    with SingleTickerProviderStateMixin {
  late final _palette = ValueNotifier(widget.dark ? _dark : _light);
  late AppPalette _from = _palette.value;
  late AppPalette _to = _palette.value;
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..addListener(_tick);

  @override
  void initState() {
    super.initState();
    AppColors.setPalette(_palette.value);
  }

  void _tick() {
    final palette = AppPalette.lerp(
      _from,
      _to,
      Curves.easeInOutCubic.transform(_controller.value),
    );
    AppColors.setPalette(palette);
    _palette.value = palette;
  }

  @override
  void didUpdateWidget(AnimatedAppPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dark == widget.dark) return;
    _from = _palette.value;
    _to = widget.dark ? _dark : _light;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _palette.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AppPaletteScope(palette: _palette, child: widget.child);
}
