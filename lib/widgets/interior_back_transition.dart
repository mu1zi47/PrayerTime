import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// Interactive back navigation inside the page; OS gesture margins stay free.
class InteriorBackTransitionsBuilder extends PageTransitionsBuilder {
  const InteriorBackTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  DelegatedTransitionBuilder get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: route.popGestureInProgress,
      child: _BackSwipeSurface(route: route, child: child),
    );
  }
}

class _BackSwipeSurface extends StatefulWidget {
  final PageRoute<dynamic> route;
  final Widget child;

  const _BackSwipeSurface({required this.route, required this.child});

  @override
  State<_BackSwipeSurface> createState() => _BackSwipeSurfaceState();
}

class _BackSwipeSurfaceState extends State<_BackSwipeSurface> {
  NavigatorState? _gestureNavigator;
  double _width = 1;

  void _start() {
    _width = context.size!.width;
    _gestureNavigator = widget.route.navigator;
    _gestureNavigator!.didStartUserGesture();
  }

  void _update(double delta) {
    if (_gestureNavigator == null || !widget.route.isCurrent) return;
    // Drive the route controller, matching Flutter’s Cupertino back transition.
    // ignore: invalid_use_of_protected_member
    final controller = widget.route.controller!;
    controller.value -= delta / _width;
  }

  Future<void> _finish(double velocity, {bool cancel = false}) async {
    if (_gestureNavigator == null) return;
    final route = widget.route;
    // ignore: invalid_use_of_protected_member
    final controller = route.controller!;
    final pop =
        !cancel &&
        route.isCurrent &&
        (velocity.abs() > _width ? velocity > 0 : controller.value < 0.6);
    if (pop) route.navigator!.pop();
    try {
      if (!route.isActive || pop) {
        await controller
            .animateBack(
              0,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } else {
        await controller
            .animateTo(
              1,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      }
    } on TickerCanceled {
      // Another navigation action may remove the route during the gesture.
    } finally {
      final navigator = _gestureNavigator;
      _gestureNavigator = null;
      if (navigator != null && navigator.mounted) {
        navigator.didStopUserGesture();
      }
    }
  }

  @override
  void dispose() {
    final navigator = _gestureNavigator;
    _gestureNavigator = null;
    if (navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted) navigator.didStopUserGesture();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.systemGestureInsetsOf(context);
    final size = MediaQuery.sizeOf(context);
    final region = Rect.fromLTRB(
      math.max(24, insets.left),
      0,
      size.width - math.max(24, insets.right),
      size.height - math.max(24, insets.bottom),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: {
              _InteriorBackRecognizer:
                  GestureRecognizerFactoryWithHandlers<_InteriorBackRecognizer>(
                    _InteriorBackRecognizer.new,
                    (recognizer) {
                      recognizer.canStart = () =>
                          widget.route.popGestureEnabled &&
                          _gestureNavigator == null;
                      recognizer.region = region;
                      recognizer.onStart = _start;
                      recognizer.onUpdate = _update;
                      recognizer.onEnd = (velocity) => _finish(velocity);
                      recognizer.onCancel = () => _finish(0, cancel: true);
                    },
                  ),
            },
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

/// Claims only deliberate rightward movement, before horizontal child pagers.
/// Leftward and vertical movement is passed through to the screen as usual.
class _InteriorBackRecognizer extends OneSequenceGestureRecognizer {
  late bool Function() canStart;
  late Rect region;
  late VoidCallback onStart;
  late ValueChanged<double> onUpdate;
  late ValueChanged<double> onEnd;
  late VoidCallback onCancel;
  int? _pointer;
  Offset _origin = Offset.zero;
  Offset _last = Offset.zero;
  VelocityTracker? _velocity;
  bool _accepted = false;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _pointer == null &&
      canStart() &&
      region.contains(event.position) &&
      super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointer = event.pointer;
    _origin = _last = event.position;
    _accepted = false;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    if (event is PointerMoveEvent) {
      final movement = event.position - _origin;
      if (!_accepted) {
        if (movement.dx < -12 ||
            (movement.dy.abs() > 12 && movement.dy.abs() > movement.dx.abs())) {
          resolve(GestureDisposition.rejected);
          return;
        }
        if (movement.dx > 12 && movement.dx > movement.dy.abs() * 1.3) {
          resolve(GestureDisposition.accepted);
        }
      }
      if (_accepted) onUpdate(event.position.dx - _last.dx);
      _last = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_accepted) {
        if (event is PointerCancelEvent) {
          onCancel();
        } else {
          onEnd(_velocity?.getVelocity().pixelsPerSecond.dx ?? 0);
        }
      } else {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
      _pointer = null;
      _accepted = false;
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _pointer || _accepted) return;
    _accepted = true;
    onStart();
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != _pointer) return;
    stopTrackingPointer(pointer);
    _pointer = null;
    _accepted = false;
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'interior back swipe';
}
