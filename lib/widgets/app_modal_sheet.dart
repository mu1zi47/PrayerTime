import 'package:flutter/material.dart';

import 'ambient_surface.dart';

/// Shared route, glass and drag coordination for every modal in the app.
Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  AnimationStyle? sheetAnimationStyle,
}) {
  final navigator = Navigator.of(context);
  final reduced = MediaQuery.disableAnimationsOf(context);
  final controller = _SheetAnimationController(
    vsync: navigator,
    duration: reduced
        ? Duration.zero
        : sheetAnimationStyle?.duration ?? const Duration(milliseconds: 300),
    reverseDuration: reduced
        ? Duration.zero
        : sheetAnimationStyle?.reverseDuration ??
              const Duration(milliseconds: 240),
    entranceCurve: sheetAnimationStyle?.curve ?? Curves.easeOutCubic,
    exitCurve: sheetAnimationStyle?.reverseCurve ?? Curves.easeInCubic,
  );
  final localizations = MaterialLocalizations.of(context);
  final route = ModalBottomSheetRoute<T>(
    builder: (context) =>
        _SheetDragSurface(controller: controller, child: builder(context)),
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    elevation: 0,
    enableDrag: false,
    showDragHandle: false,
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint: localizations.scrimOnTapHint(
      localizations.bottomSheetLabel,
    ),
    modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
    transitionAnimationController: controller,
    // Easing belongs to the controller's entrance/exit animations. Direct
    // values while dragging must map one-to-one to finger displacement.
    sheetAnimationStyle: const AnimationStyle(
      curve: Curves.linear,
      reverseCurve: Curves.linear,
    ),
  );
  final result = navigator.push(route);
  // Route results arrive before the exit transition has finished.
  route.completed.whenComplete(controller.dispose);
  return result;
}

class _SheetDragSurface extends StatefulWidget {
  final AnimationController controller;
  final Widget child;
  const _SheetDragSurface({required this.controller, required this.child});
  @override
  State<_SheetDragSurface> createState() => _SheetDragSurfaceState();
}

class _SheetDragSurfaceState extends State<_SheetDragSurface> {
  final _surface = GlobalKey();
  bool _dragging = false;
  bool _closing = false;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _closing = true;
    _dragging = false;
    super.dispose();
  }

  double get _height =>
      (_surface.currentContext?.findRenderObject() as RenderBox?)
          ?.size
          .height ??
      1;

  /// Return the part of the movement that still belongs to list scrolling.
  double _move(double delta) {
    if (_closing ||
        _route?.isCurrent != true ||
        (!_dragging && !widget.controller.isCompleted)) {
      return delta;
    }
    if (!_dragging && delta < 0) return delta;
    _dragging = true;
    widget.controller.stop();
    final height = _height.clamp(1.0, double.infinity);
    final before = (1 - widget.controller.value) * height;
    final after = (before + delta).clamp(0.0, height * .999);
    widget.controller.value = 1 - after / height;
    return delta - (after - before);
  }

  bool _release(double scrollVelocity) {
    if (!_dragging) return false;
    _dragging = false;
    if (_closing || _route?.isCurrent != true) return true;
    if (widget.controller.value >= 1) return false;
    final close =
        scrollVelocity < -700 ||
        (scrollVelocity.abs() <= 700 && widget.controller.value < .65);
    if (close) {
      _closing = true;
      Navigator.of(context).pop();
    } else {
      widget.controller.animateTo(
        1,
        curve: Curves.easeOutCubic,
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
        ),
      );
    }
    return true;
  }

  void _cancel() {
    if (!_dragging || _closing || _route?.isCurrent != true) return;
    _dragging = false;
    widget.controller.animateTo(
      1,
      curve: Curves.easeOutCubic,
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerCancel: (_) => _cancel(),
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) => _move(details.delta.dy),
      onVerticalDragEnd: (details) => _release(-(details.primaryVelocity ?? 0)),
      onVerticalDragCancel: _cancel,
      child: ScrollConfiguration(
        behavior: _SheetScrollBehavior(this),
        child: GlassPanel(key: _surface, child: widget.child),
      ),
    ),
  );
}

class _SheetScrollBehavior extends MaterialScrollBehavior {
  final _SheetDragSurfaceState drag;
  const _SheetScrollBehavior(this.drag);
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      _SheetScrollPhysics(drag, parent: const ClampingScrollPhysics());
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// A list at its upper boundary hands downward movement to the sheet.
/// Reversing the same gesture restores the sheet before scrolling the list.
class _SheetScrollPhysics extends ScrollPhysics {
  final _SheetDragSurfaceState drag;
  const _SheetScrollPhysics(this.drag, {super.parent});
  @override
  _SheetScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _SheetScrollPhysics(drag, parent: buildParent(ancestor));
  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // A minute picker is a control, rather than the sheet's content scroll.
    if (position.axis != Axis.vertical || position is FixedExtentMetrics) {
      return super.applyPhysicsToUserOffset(position, offset);
    }
    if (drag._dragging ||
        (position.pixels <= position.minScrollExtent && offset > 0)) {
      return drag._move(offset);
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.axis == Axis.vertical &&
        position is! FixedExtentMetrics &&
        drag._release(velocity)) {
      return null;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class _SheetAnimationController extends AnimationController {
  final Curve entranceCurve;
  final Curve exitCurve;
  _SheetAnimationController({
    required super.vsync,
    required super.duration,
    required super.reverseDuration,
    required this.entranceCurve,
    required this.exitCurve,
  });
  @override
  TickerFuture forward({double? from}) {
    if (from != null) value = from;
    return animateTo(1, curve: entranceCurve);
  }

  @override
  TickerFuture reverse({double? from}) {
    if (from != null) value = from;
    return animateBack(0, curve: exitCurve);
  }
}
