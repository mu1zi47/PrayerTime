import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The displayed position, shared by routes and driven by their actual motion.
final ambientPosition = ValueNotifier<Alignment>(const Alignment(-.65, -.6));

void moveAmbientLight(Alignment position) => ambientPosition.value = position;

class AmbientNavigationObserver extends NavigatorObserver {
  final _history = <Route<dynamic>, Alignment>{};
  Animation<double>? _animation;
  VoidCallback? _tick;
  AnimationStatusListener? _status;
  Route<dynamic>? _trackedRoute;
  Route<dynamic>? _gestureRoute;
  Alignment? _gestureOrigin;

  static const positions = [
    Alignment(-.65, -.6),
    Alignment(.8, -.2),
    Alignment(-.6, .65),
    Alignment(.65, -.7),
  ];
  void _detach() {
    if (_tick != null) _animation?.removeListener(_tick!);
    if (_status != null) _animation?.removeStatusListener(_status!);
    _animation = null;
    _tick = null;
    _status = null;
    _trackedRoute = null;
  }

  void _drive(
    PageRoute<dynamic> route,
    Alignment target, {
    bool reverse = false,
    double? startAt,
  }) {
    _detach();
    final animation = route.animation;
    if (animation == null) {
      moveAmbientLight(target);
      return;
    }
    var origin = ambientPosition.value;
    var start = startAt ?? animation.value;
    var previous = start;
    final end = reverse ? 0.0 : 1.0;
    _animation = animation;
    _trackedRoute = route;
    _tick = () {
      final value = animation.value;
      // Predictive back may restart its final reverse animation at 1.
      // Continue from the preview instead of jumping back to the origin.
      if (reverse && value > previous && _gestureRoute != route) {
        origin = ambientPosition.value;
        start = value;
      }
      previous = value;
      final distance = end - start;
      final progress = distance.abs() < .00001
          ? 1.0
          : ((value - start) / distance).clamp(0.0, 1.0);
      moveAmbientLight(Alignment.lerp(origin, target, progress)!);
    };
    _status = (status) {
      if ((!reverse && status == AnimationStatus.completed) ||
          (reverse && status == AnimationStatus.dismissed)) {
        moveAmbientLight(target);
        _detach();
      }
    };
    animation.addListener(_tick!);
    animation.addStatusListener(_status!);
    _tick!();
    if (animation.value == end) {
      moveAmbientLight(target);
      _detach();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && previousRoute != null) {
      _gestureRoute = null;
      _gestureOrigin = null;
      _history[route] = ambientPosition.value;
      var index = _history.length % positions.length;
      if (positions[index] == ambientPosition.value) {
        index = (index + 1) % positions.length;
      }
      _drive(route, positions[index]);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      final target = _history.remove(route);
      if (target != null) {
        _gestureRoute = null;
        _gestureOrigin = null;
        _drive(route, target, reverse: true);
      }
    }
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    final target = _history[route];
    if (route is PageRoute && target != null) {
      _gestureRoute = route;
      _gestureOrigin = ambientPosition.value;
      _drive(route, target, reverse: true, startAt: 1);
    }
  }

  @override
  void didStopUserGesture() {
    if (_gestureRoute != null) {
      // A cancelled gesture restores the exact position before the drag.
      if (_gestureOrigin != null) moveAmbientLight(_gestureOrigin!);
      _gestureRoute = null;
      _gestureOrigin = null;
      _detach();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _history.remove(route);
    if (_trackedRoute == route) _detach();
  }

  void dispose() {
    _detach();
    _history.clear();
  }
}

/// Connects only this pager's movement to the light; nested vertical lists
/// and pagers behind a new route cannot overwrite the current transition.
class AmbientPageMotion extends StatefulWidget {
  final List<Alignment> positions;
  final bool anchorToCurrent;
  final bool Function()? shouldTrack;
  final Widget child;
  const AmbientPageMotion({
    super.key,
    required this.positions,
    this.anchorToCurrent = true,
    this.shouldTrack,
    required this.child,
  });

  @override
  State<AmbientPageMotion> createState() => _AmbientPageMotionState();
}

class _AmbientPageMotionState extends State<AmbientPageMotion> {
  List<Alignment>? _anchors;

  bool _onScroll(ScrollNotification notification) {
    if (widget.shouldTrack?.call() == false ||
        notification.depth != 0 ||
        notification.metrics is! PageMetrics ||
        ModalRoute.of(context)?.isCurrent == false ||
        Navigator.maybeOf(context)?.userGestureInProgress == true) {
      return false;
    }
    final page = (notification.metrics as PageMetrics).page;
    if (page == null || widget.positions.isEmpty) return false;
    if (notification is ScrollStartNotification) {
      if (widget.anchorToCurrent && _anchors == null) {
        _anchors = List.of(widget.positions);
        _anchors![page.round().clamp(0, _anchors!.length - 1)] =
            ambientPosition.value;
      }
    } else if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final anchors = widget.anchorToCurrent
          ? _anchors ?? widget.positions
          : widget.positions;
      final progress = page.clamp(0.0, (anchors.length - 1).toDouble());
      final lower = progress.floor();
      final upper = progress.ceil();
      moveAmbientLight(
        Alignment.lerp(anchors[lower], anchors[upper], progress - lower)!,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      );
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
  Widget build(BuildContext context) => _PanelBlurScope(
    // This route's background is already a diffuse glow. Filtering it
    // again adds a full-screen GPU pass without visible extra detail.
    enabled: false,
    child: Stack(
      children: [
        const Positioned.fill(child: AmbientBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
        ),
      ],
    ),
  );
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});
  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AmbientPainter(
            background: AppColors.bg,
            accent: AppColors.accent,
            dark: dark,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Finger updates repaint this layer without rebuilding screens or panels.
class _AmbientPainter extends CustomPainter {
  final Color background;
  final Color accent;
  final bool dark;
  _AmbientPainter({
    required this.background,
    required this.accent,
    required this.dark,
  }) : super(repaint: ambientPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final alignment = ambientPosition.value;
    canvas.drawRect(rect, Paint()..color = background);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: alignment,
          radius: 1.05,
          colors: [
            accent.withValues(alpha: dark ? .24 : .18),
            accent.withValues(alpha: dark ? .08 : .06),
            Colors.transparent,
          ],
          stops: const [0, .45, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-alignment.x, -alignment.y),
          radius: .85,
          colors: [
            accent.withValues(alpha: dark ? .14 : .12),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      background != oldDelegate.background ||
      accent != oldDelegate.accent ||
      dark != oldDelegate.dark;
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

final _panelBlur = ImageFilter.blur(sigmaX: 6, sigmaY: 6);

class _PanelBlurScope extends InheritedWidget {
  final bool enabled;
  const _PanelBlurScope({required this.enabled, required super.child});
  @override
  bool updateShouldNotify(_PanelBlurScope oldWidget) =>
      enabled != oldWidget.enabled;
}

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
    final needsBlur =
        context
            .dependOnInheritedWidgetOfExactType<_PanelBlurScope>()
            ?.enabled ??
        true;
    final surface = Container(
      decoration: glassDecoration().copyWith(
        border: Border.fromBorderSide(BorderSide.none),
        // A shadow outside this clip is invisible; don't rasterize it.
        boxShadow: const [],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.text.withValues(alpha: .08)),
      ),
      padding: padding,
      // Modal content already sits on filtered glass. Nested panels need
      // their fill and outline, not another blur of the same backdrop.
      child: _PanelBlurScope(enabled: false, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: needsBlur
          ? BackdropFilter.grouped(
              filter: _panelBlur,
              child: RepaintBoundary(child: surface),
            )
          : surface,
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
