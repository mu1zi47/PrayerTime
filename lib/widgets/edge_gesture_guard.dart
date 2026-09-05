import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Stops descendant gestures/scrolling (swipe navigation, PageView paging,
/// ListView scrolling) from claiming a touch that starts within the OS's
/// reserved system-gesture margins — the edge back-swipe strip on the
/// sides, and the swipe-up-to-home/minimize strip along the bottom.
///
/// This app deliberately draws edge-to-edge (see the "No SafeArea —
/// content should scroll under the transparent system bars" comments
/// throughout), so a full-width swipeable PageView or a ListView that
/// reaches the very edge can win the gesture-arena race against Android's
/// own back/home gesture — Flutter's touch dispatch has no innate concept
/// of "this belongs to the OS". [MediaQuery.systemGestureInsets] is exactly
/// the signal Flutter exposes for this, and this widget acts on it at the
/// hit-test level — before any gesture recognizer, ours or the system's,
/// gets involved — rather than reactively after a drag has already begun,
/// which would be too late to matter.
class EdgeGestureGuard extends SingleChildRenderObjectWidget {
  final bool left;
  final bool right;
  final bool bottom;

  /// Left/right rejection is skipped entirely above this height — for a
  /// scrolling page whose own top content (e.g. a header row with buttons
  /// near the edges) needs to stay tappable at rest, without hoisting that
  /// content out of the page into some separately-positioned overlay. 0
  /// (the default) applies left/right for the full height, same as before.
  final double topExclusion;

  const EdgeGestureGuard({
    super.key,
    this.left = false,
    this.right = false,
    this.bottom = false,
    this.topExclusion = 0,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEdgeGestureGuard(
      insets: MediaQuery.systemGestureInsetsOf(context),
      left: left,
      right: right,
      bottom: bottom,
      topExclusion: topExclusion,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEdgeGestureGuard)
      ..insets = MediaQuery.systemGestureInsetsOf(context)
      ..left = left
      ..right = right
      ..bottom = bottom
      ..topExclusion = topExclusion;
  }
}

class _RenderEdgeGestureGuard extends RenderProxyBox {
  EdgeInsets insets;
  bool left;
  bool right;
  bool bottom;
  double topExclusion;

  _RenderEdgeGestureGuard({
    required this.insets,
    required this.left,
    required this.right,
    required this.bottom,
    required this.topExclusion,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Returning false here means this touch never reaches our child (or
    // any gesture recognizer inside it) — it's as if nothing of ours was
    // there at all, leaving it free for the OS to interpret.
    if (position.dy >= topExclusion) {
      if (left && position.dx < insets.left) return false;
      if (right && position.dx > size.width - insets.right) return false;
    }
    if (bottom && position.dy > size.height - insets.bottom) return false;
    return super.hitTest(result, position: position);
  }
}
