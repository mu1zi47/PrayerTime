import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared atmosphere: navigation moves the light, rather than restarting it.
Alignment _previousAmbientPosition = const Alignment(-.65, -.6);

void moveAmbientLight(Alignment position) {
  if (ambientPosition.value == position) return;
  _previousAmbientPosition = ambientPosition.value;
  ambientPosition.value = position;
}

final ambientPosition = ValueNotifier<Alignment>(const Alignment(-.65, -.6));

class AmbientNavigationObserver extends NavigatorObserver {
  final _history = <Alignment>[];
  int _depth = 0;
  static const positions = [
    Alignment(-.65, -.6),
    Alignment(.8, -.2),
    Alignment(-.6, .65),
    Alignment(.65, -.7),
  ];
  void _move() {
    var target = positions[_depth % positions.length];
    if (target == ambientPosition.value) {
      target = positions[(_depth + 1) % positions.length];
    }
    moveAmbientLight(target);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) {
      _history.add(ambientPosition.value);
      _depth++;
      _move();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _depth = (_depth - 1).clamp(0, 999);
      if (_history.isNotEmpty) moveAmbientLight(_history.removeLast());
    }
  }
}

class AmbientScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  const AmbientScaffold({
    super.key,
    this.body,
    this.appBar,
    this.backgroundColor,
  });
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: AmbientBackground()),
      Scaffold(backgroundColor: Colors.transparent, appBar: appBar, body: body),
    ],
  );
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});
  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: ValueListenableBuilder<Alignment>(
          valueListenable: ambientPosition,
          builder: (context, position, _) => TweenAnimationBuilder<Alignment>(
            tween: AlignmentTween(
              begin: _previousAmbientPosition,
              end: position,
            ),
            duration: Duration(milliseconds: reduceMotion ? 0 : 850),
            curve: Curves.easeInOutCubic,
            builder: (context, alignment, _) => ColoredBox(
              color: AppColors.bg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: alignment,
                    radius: 1.05,
                    colors: [
                      AppColors.accent.withValues(alpha: dark ? .24 : .18),
                      AppColors.accent.withValues(alpha: dark ? .08 : .06),
                      Colors.transparent,
                    ],
                    stops: const [0, .45, 1],
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-alignment.x, -alignment.y),
                      radius: .85,
                      colors: [
                        AppColors.accent.withValues(alpha: dark ? .14 : .12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration glassDecoration({double radius = AppRadius.lg}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surface.withValues(alpha: .78),
      AppColors.surface.withValues(alpha: .48),
    ],
  ),
  border: Border.all(color: AppColors.text.withValues(alpha: .08)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: .045),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ],
);

final _panelBlur = ImageFilter.blur(sigmaX: 14, sigmaY: 14);

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter.grouped(
        filter: _panelBlur,
        child: Container(
          decoration: glassDecoration().copyWith(
            border: Border.fromBorderSide(BorderSide.none),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.text.withValues(alpha: .08)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key});
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: .6,
    indent: 0,
    endIndent: 0,
    color: AppColors.divider,
  );
}

/// Full-width row paint and hit area, with content and separator inset.
class PanelRow extends StatelessWidget {
  final Widget child;
  final bool showDivider;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool selected;
  const PanelRow({
    super.key,
    required this.child,
    this.showDivider = false,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        decoration: BoxDecoration(
          color: color,
          gradient: selected ? AppColors.selectionGradient : null,
        ),
        padding: padding,
        child: child,
      ),
      if (showDivider) const PanelDivider(),
    ],
  );
}

/// Screen spacing only; rounded clipping belongs to individual panels.
class ScreenContentInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  const ScreenContentInset({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    // Screen panels do not overlap. Their filters can share one backdrop
    // calculation; sheets and other routes have independent groups.
    child: BackdropGroup(child: child),
  );
}

/// Stretching overscroll composites backdrop filters into an opaque layer.
/// Keep the panel stationary at either end of its scroll range instead.
class StableScrollBehavior extends MaterialScrollBehavior {
  const StableScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
