import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;

/// Keep the hit area stationary. Decorated rows opt into explicit content
/// feedback so their fills, borders and dividers never change size.
class AppTap extends GestureDetector {
  AppTap({
    super.key,
    Widget? child,
    bool feedbackOnChild = true,
    super.onTap,
    super.behavior = HitTestBehavior.opaque,
    super.onHorizontalDragStart,
    super.onHorizontalDragUpdate,
    super.onHorizontalDragEnd,
    super.onPanStart,
    super.onPanUpdate,
    super.onPanEnd,
    super.onLongPressStart,
    super.onLongPressMoveUpdate,
    super.onLongPressEnd,
    super.onLongPressCancel,
  }) : super(
         child: feedbackOnChild && child != null
             ? AppPressContent(child: child)
             : child,
       );

  @override
  Widget build(BuildContext context) =>
      _PressFeedback(enabled: onTap != null, child: super.build(context));
}

class _PressFeedback extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const _PressFeedback({required this.enabled, required this.child});

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  int? _pointer;
  Offset? _origin;
  bool _pressed = false;
  bool _cancelled = false;

  void _release({bool cancelled = false}) {
    _cancelled = cancelled;
    _pointer = null;
    _origin = null;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  void didUpdateWidget(covariant _PressFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointer = null;
      _origin = null;
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) {
      if (!widget.enabled || _pointer != null) return;
      _cancelled = false;
      _pointer = event.pointer;
      _origin = event.position;
      setState(() => _pressed = true);
    },
    onPointerMove: (event) {
      if (event.pointer == _pointer &&
          (event.position - _origin!).distance > kTouchSlop) {
        _release(cancelled: true);
      }
    },
    onPointerUp: (event) {
      if (event.pointer == _pointer) _release();
    },
    onPointerCancel: (event) {
      if (event.pointer == _pointer) _release(cancelled: true);
    },
    child: _PressScope(
      pressed: _pressed && widget.enabled,
      instant: _cancelled,
      child: widget.child,
    ),
  );
}

class _PressScope extends InheritedWidget {
  final bool pressed;
  final bool instant;
  const _PressScope({
    required this.pressed,
    required this.instant,
    required super.child,
  });
  @override
  bool updateShouldNotify(_PressScope oldWidget) =>
      pressed != oldWidget.pressed || instant != oldWidget.instant;
}

/// Wrap only the foreground of a decorated tappable surface.
class AppPressContent extends StatelessWidget {
  final Widget child;
  const AppPressContent({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_PressScope>();
    if (scope == null) return child;
    return AnimatedScale(
      scale: scope.pressed ? .97 : 1,
      duration: Duration(
        milliseconds: scope.instant || MediaQuery.disableAnimationsOf(context)
            ? 0
            : 110,
      ),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}
