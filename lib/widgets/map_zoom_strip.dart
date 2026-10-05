import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../l10n/app_localizations.dart';
import '../services/system_gestures_bridge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// What a finger on the zoom strip is doing.
enum _StripMode {
  idle,

  /// Down, not yet moved — a zoom drag if it moves along the strip, a
  /// "move the strip" long press if it stays put as long as the phone's
  /// long-press delay.
  pending,
  zooming,

  /// Held long enough: the strip has come off the edge and follows the
  /// finger sideways.
  relocating,

  /// Gliding to the other edge, or back to its own.
  flying,

  /// Moved sideways before the hold finished — not a gesture for the strip.
  ignored,
}

/// The zoom control: a thin gauge growing out of the side of the screen,
/// shaped like a front-camera cutout — square against the edge, rounded on
/// the inside, with small inward curves where it meets the edge — filled
/// gold from the bottom up to the current zoom.
///
/// Drag along it like a volume slider: up zooms in, down zooms out, the
/// fill following the finger one to one, with a tick on every whole zoom
/// level. Long-press it (the phone's own delay) and it comes off the edge: a
/// button offers to move it to the other side, or, without letting go, it
/// can be dragged across and dropped there.
class MapZoomStrip extends StatefulWidget {
  final MapController controller;
  final double minZoom;
  final double maxZoom;
  final bool onLeft;
  final ValueChanged<bool> onSideChanged;

  /// Fires when the map itself is touched — the cue to put away the "move"
  /// button.
  final Listenable mapTouched;
  final VoidCallback onInteractionStart;

  const MapZoomStrip({
    super.key,
    required this.controller,
    required this.minZoom,
    required this.maxZoom,
    required this.onLeft,
    required this.onSideChanged,
    required this.mapTouched,
    required this.onInteractionStart,
  });

  @override
  State<MapZoomStrip> createState() => _MapZoomStripState();
}

class _MapZoomStripState extends State<MapZoomStrip>
    with TickerProviderStateMixin {
  static const _trackHeight = 260.0;
  static const _boxHeight = _trackHeight + _StripPainter.verticalInset * 2;

  /// The touch area reaches well into the screen, so the thin strip is
  /// easy to grab.
  static const _hitWidth = 40.0;

  /// Room beside the strip for the "move" button.
  static const _buttonRoom = 220.0;

  static const _restWidth = 4.0;
  static const _activeWidth = 6.0;
  static const _liftedWidth = 9.0;

  /// Android gives an app back at most 200dp of each edge from the system
  /// back gesture; the strip's middle gets it.
  static const _excludedHeight = 200.0;

  late final AnimationController _holdProgress = AnimationController(
    vsync: this,
    // Until the phone's own setting has been read (see initState).
    duration: kLongPressTimeout,
  )..addStatusListener(_onHoldStatus);

  /// 1 docked against the edge, 0 free of it.
  late final AnimationController _dock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  late final AnimationController _fly = AnimationController(vsync: this);
  late final AnimationController _ghost = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final AnimationController _button = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 160),
  );

  _StripMode _mode = _StripMode.idle;
  int? _pointer;
  Offset _downAt = Offset.zero;
  late double _zoomAtDown = widget.minZoom;
  late double _lastZoom = widget.minZoom;

  double _width = _restWidth;

  /// How far the strip has been pulled sideways, in logical pixels.
  double _dx = 0;
  bool _armed = false;
  Timer? _buttonTimeout;

  final _zoneKey = GlobalKey();
  static const _gestures = SystemGesturesBridge();
  Rect? _excluded;

  double get _screenWidth => MediaQuery.sizeOf(context).width;

  /// How far the strip may travel: from its own edge to flush with the
  /// other one.
  double get _travel => _screenWidth - _width;

  @override
  void initState() {
    super.initState();
    widget.mapTouched.addListener(_hideButton);
    // A long press as long as everywhere else on the phone.
    _gestures.longPressTimeout().then((timeout) {
      if (mounted) _holdProgress.duration = timeout;
    });
  }

  @override
  void didUpdateWidget(MapZoomStrip old) {
    super.didUpdateWidget(old);
    if (old.mapTouched != widget.mapTouched) {
      old.mapTouched.removeListener(_hideButton);
      widget.mapTouched.addListener(_hideButton);
    }
  }

  @override
  void dispose() {
    widget.mapTouched.removeListener(_hideButton);
    _buttonTimeout?.cancel();
    _holdProgress.dispose();
    _dock.dispose();
    _fly.dispose();
    _ghost.dispose();
    _button.dispose();
    _gestures.excludeFromBackGesture(const []);
    super.dispose();
  }

  /// Keeps the system back gesture off the strip: it sits on the edge,
  /// where a swipe would otherwise go "back" instead of zooming.
  void _excludeFromBackGesture() {
    if (!mounted) return;
    final box = _zoneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final zone = box.localToGlobal(Offset.zero) & box.size;
    final rect = Rect.fromCenter(
      center: zone.center,
      width: zone.width,
      height: math.min(zone.height, _excludedHeight),
    );
    if (rect == _excluded) return;
    _excluded = rect;
    _gestures.excludeFromBackGesture([rect]);
  }

  void _setWidth(double width) {
    if (width != _width) setState(() => _width = width);
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_pointer != null || _mode == _StripMode.flying) return;
    _pointer = e.pointer;
    _downAt = e.position;
    _zoomAtDown = _lastZoom = widget.controller.camera.zoom;
    _mode = _StripMode.pending;
    widget.onInteractionStart();
    _hideButton();
    _setWidth(_activeWidth);
    _holdProgress.forward(from: 0);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final delta = e.position - _downAt;
    switch (_mode) {
      case _StripMode.pending:
        if (delta.dy.abs() > 6) {
          _mode = _StripMode.zooming;
          _cancelHold();
          _zoomBy(delta.dy);
        } else if (delta.dx.abs() > 14) {
          _mode = _StripMode.ignored;
          _cancelHold();
          _setWidth(_restWidth);
        }
      case _StripMode.zooming:
        _zoomBy(delta.dy);
      case _StripMode.relocating:
        _pullTo(delta.dx);
      default:
        break;
    }
  }

  void _onPointerUp(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    switch (_mode) {
      case _StripMode.pending:
      case _StripMode.zooming:
      case _StripMode.ignored:
        _cancelHold();
        _mode = _StripMode.idle;
        _setWidth(_restWidth);
      case _StripMode.relocating:
        final pulled = widget.onLeft ? _dx : -_dx;
        if (_armed && e is PointerUpEvent) {
          _moveToOtherSide();
        } else if (pulled < 10) {
          // Just the hold, no pull: leave the button up to be tapped.
          _mode = _StripMode.idle;
          _dock.animateTo(1, curve: Curves.easeOutCubic);
          setState(() => _dx = 0);
          _buttonTimeout?.cancel();
          _buttonTimeout = Timer(const Duration(seconds: 5), _hideButton);
        } else {
          _settleBack();
        }
      default:
        break;
    }
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _mode != _StripMode.pending) {
      return;
    }
    _mode = _StripMode.relocating;
    // The phone's standard long-press buzz, the same as any other app's.
    Feedback.forLongPress(context);
    _setWidth(_liftedWidth);
    _dock.animateTo(0.75, curve: Curves.easeOut);
    _button.forward();
    // The glow has done its job; let it fade as the strip lifts.
    _holdProgress.animateBack(0, duration: const Duration(milliseconds: 260));
  }

  void _cancelHold() {
    if (_holdProgress.value > 0) {
      _holdProgress.animateBack(0, duration: const Duration(milliseconds: 150));
    } else {
      _holdProgress.stop();
    }
  }

  void _zoomBy(double dy) {
    final min = widget.minZoom;
    final max = widget.maxZoom;
    final zoom = (_zoomAtDown - dy / _trackHeight * (max - min)).clamp(
      min,
      max,
    );
    if (zoom.floor() != _lastZoom.floor() ||
        (zoom == max) != (_lastZoom == max)) {
      HapticFeedback.selectionClick();
    }
    _lastZoom = zoom;
    widget.controller.move(widget.controller.camera.center, zoom);
  }

  /// Follows the finger sideways: the further it goes, the more the strip
  /// lets go of its edge; past the middle of the screen the other edge
  /// lights up as the place it will land.
  void _pullTo(double dx) {
    final pulled = (widget.onLeft ? dx : -dx).clamp(-8.0, _travel);
    if (pulled > 20) _hideButton();
    _dock.value = 0.75 * (1 - (pulled / 32).clamp(0.0, 1.0));
    final armed = pulled > _screenWidth / 2 - _hitWidth;
    if (armed != _armed) {
      HapticFeedback.selectionClick();
      armed ? _ghost.forward() : _ghost.reverse();
    }
    setState(() {
      _armed = armed;
      _dx = widget.onLeft ? pulled : -pulled;
    });
  }

  Future<void> _flyTo(double target) async {
    final from = _dx;
    final distance = (target - from).abs();
    _fly.duration = Duration(
      milliseconds: (220 + 260 * distance / _screenWidth).round(),
    );
    final curve = CurvedAnimation(parent: _fly, curve: Curves.easeInOutCubic);
    void tick() => setState(() => _dx = lerpDouble(from, target, curve.value)!);
    _fly.addListener(tick);
    try {
      await _fly.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Disposed mid-flight.
    } finally {
      _fly.removeListener(tick);
      curve.dispose();
    }
  }

  /// Off one edge, across, and onto the other — then remembered there.
  Future<void> _moveToOtherSide() async {
    if (_mode == _StripMode.flying) return;
    _mode = _StripMode.flying;
    _hideButton();
    _ghost.reverse();
    _armed = false;
    _setWidth(_liftedWidth);
    final target = widget.onLeft ? _travel : -_travel;
    await Future.wait([
      _dock.animateTo(0, duration: const Duration(milliseconds: 140)),
      _flyTo(target),
    ]);
    if (!mounted) return;
    // Now flush with the other edge: hand the strip over to that side and
    // let it take hold of the edge there.
    widget.onSideChanged(!widget.onLeft);
    setState(() => _dx = 0);
    HapticFeedback.mediumImpact();
    _setWidth(_restWidth);
    await _dock.animateTo(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _mode = _StripMode.idle;
  }

  /// Not pulled far enough: back to its own edge.
  Future<void> _settleBack() async {
    _mode = _StripMode.flying;
    _hideButton();
    _ghost.reverse();
    _armed = false;
    await _flyTo(0);
    if (!mounted) return;
    _setWidth(_restWidth);
    await _dock.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _mode = _StripMode.idle;
  }

  void _hideButton() {
    _buttonTimeout?.cancel();
    if (_button.isDismissed || _button.status == AnimationStatus.reverse) {
      return;
    }
    _button.reverse();
    if (_mode == _StripMode.idle) {
      _setWidth(_restWidth);
      _dock.animateTo(1, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _excludeFromBackGesture(),
    );
    final t = AppLocalizations.of(context)!;
    final onLeft = widget.onLeft;
    final screenWidth = _screenWidth;

    final strip = TweenAnimationBuilder<double>(
      tween: Tween(end: _width),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, width, _) => AnimatedBuilder(
        animation: Listenable.merge([_holdProgress, _dock, _ghost]),
        builder: (context, _) => StreamBuilder<MapEvent>(
          stream: widget.controller.mapEventStream,
          builder: (context, _) {
            final zoom = widget.controller.camera.zoom;
            return CustomPaint(
              size: const Size(_hitWidth, _boxHeight),
              painter: _StripPainter(
                onLeft: onLeft,
                width: math.max(width, 1),
                dx: _dx,
                dock: _dock.value,
                fraction:
                    ((zoom - widget.minZoom) /
                            (widget.maxZoom - widget.minZoom))
                        .clamp(0.0, 1.0),
                // Only once the touch is clearly a hold — a zoom drag
                // gets moving well before a quarter of the delay is up.
                glow: Curves.easeIn.transform(
                  ((_holdProgress.value - 0.25) / 0.75).clamp(0.0, 1.0),
                ),
                ghost: _ghost.value,
                screenWidth: screenWidth,
                gauge: AppColors.accent,
                track: AppColors.surface,
                outline: AppColors.neutral500.withValues(alpha: 0.45),
              ),
            );
          },
        ),
      ),
    );

    final button = AnimatedBuilder(
      animation: _button,
      builder: (context, child) {
        // Gone from the tree while hidden, rather than just see-through.
        if (_button.isDismissed) return const SizedBox.shrink();
        final v = _button.value;
        // Springs out on the way in, simply shrinks on the way out.
        final shown = _button.status == AnimationStatus.reverse
            ? Curves.easeIn.transform(v)
            : Curves.easeOutBack.transform(v);
        return IgnorePointer(
          ignoring: _button.value < 0.5,
          child: Opacity(
            opacity: _button.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset((onLeft ? -16 : 16) * (1 - shown), 0),
              child: Transform.scale(
                scale: 0.6 + 0.4 * shown,
                alignment: onLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: child,
              ),
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.neutral900.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: _moveToOtherSide,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  onLeft ? Icons.east_rounded : Icons.west_rounded,
                  size: 18,
                  color: AppColors.accent700,
                ),
                const SizedBox(width: 8),
                Text(
                  onLeft ? t.zoomBarMoveRight : t.zoomBarMoveLeft,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: _hitWidth + _buttonRoom,
      height: _boxHeight,
      // Only the strip's own zone and the button take touches; the rest of
      // this box lets them through to the map.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            key: _zoneKey,
            left: onLeft ? 0 : null,
            right: onLeft ? null : 0,
            top: 0,
            bottom: 0,
            width: _hitWidth,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: strip,
            ),
          ),
          Positioned(
            left: onLeft ? 20 : null,
            right: onLeft ? null : 20,
            top: 0,
            bottom: 0,
            child: Center(child: button),
          ),
        ],
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  final bool onLeft;
  final double width;
  final double dx;

  /// 1 docked against the edge, 0 a free pill.
  final double dock;
  final double fraction;

  /// The halo building up while the strip is held.
  final double glow;

  /// The outline of where the strip would land on the other edge.
  final double ghost;
  final double screenWidth;
  final Color gauge;
  final Color track;
  final Color outline;

  const _StripPainter({
    required this.onLeft,
    required this.width,
    required this.dx,
    required this.dock,
    required this.fraction,
    required this.glow,
    required this.ghost,
    required this.screenWidth,
    required this.gauge,
    required this.track,
    required this.outline,
  });

  /// Room above and below for the inward curves where the strip meets the
  /// edge.
  static const verticalInset = 4.5;

  /// The strip against the edge at [edgeX] — on its right when [right] —
  /// reaching [width] in from it.
  ui.Path _shape(
    double edgeX,
    bool right,
    double width,
    double dock,
    Size size,
  ) {
    const top = verticalInset;
    final bottom = size.height - verticalInset;
    final r = width / 2;
    // Docked: square against the edge, with concave curves flaring into
    // it — a punch-hole cutout's outline. Free: a plain pill.
    final edgeCorner = Radius.circular(r * (1 - dock));
    final fillet = math.min(r, verticalInset) * dock;

    // Built against an edge at x = 0 with the strip to its left, then
    // moved (and mirrored for the left side) into place.
    var path = ui.Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          -width,
          top,
          0,
          bottom,
          topLeft: Radius.circular(r),
          bottomLeft: Radius.circular(r),
          topRight: edgeCorner,
          bottomRight: edgeCorner,
        ),
      );
    if (fillet > 0.05) {
      final flares = ui.Path()
        ..moveTo(0, top - fillet)
        ..arcToPoint(Offset(-fillet, top), radius: Radius.circular(fillet))
        ..lineTo(0, top)
        ..close()
        ..moveTo(-fillet, bottom)
        ..arcToPoint(
          Offset(0, bottom + fillet),
          radius: Radius.circular(fillet),
        )
        ..lineTo(0, bottom)
        ..close();
      path = ui.Path.combine(ui.PathOperation.union, path, flares);
    }
    final m = Float64List(16)
      ..[0] = right ? 1 : -1
      ..[5] = 1
      ..[10] = 1
      ..[12] = edgeX
      ..[15] = 1;
    return path.transform(m);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ownEdge = onLeft ? 0.0 : size.width;

    if (ghost > 0) {
      // The other screen edge, in this box's coordinates.
      final otherEdge = onLeft ? screenWidth : size.width - screenWidth;
      final slot = _shape(
        otherEdge,
        onLeft,
        _MapZoomStripState._restWidth + 2,
        1,
        size,
      );
      canvas.drawPath(
        slot,
        Paint()..color = gauge.withValues(alpha: 0.25 * ghost),
      );
      canvas.drawPath(
        slot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = gauge.withValues(alpha: 0.8 * ghost),
      );
    }

    final shape = _shape(ownEdge + dx, !onLeft, width, dock, size);

    if (glow > 0) {
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 6 * glow
          ..color = gauge.withValues(alpha: 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 4 * glow),
      );
    }

    // Lifted off the edge, it casts a deeper shadow.
    canvas.drawShadow(shape, Colors.black, 2 + 5 * (1 - dock), false);
    canvas.drawPath(shape, Paint()..color = track);
    if (fraction > 0) {
      final bounds = shape.getBounds();
      canvas.save();
      canvas.clipPath(shape);
      // Over the full height, the curves at either end included.
      canvas.drawRect(
        Rect.fromLTRB(
          bounds.left,
          size.height * (1 - fraction),
          bounds.right,
          size.height,
        ),
        Paint()..color = gauge,
      );
      canvas.restore();
    }
    // A hairline round the empty part, which is otherwise light on a
    // mostly light map.
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_StripPainter old) =>
      old.onLeft != onLeft ||
      old.width != width ||
      old.dx != dx ||
      old.dock != dock ||
      old.fraction != fraction ||
      old.glow != glow ||
      old.ghost != ghost ||
      old.screenWidth != screenWidth ||
      old.gauge != gauge ||
      old.track != track ||
      old.outline != outline;
}
