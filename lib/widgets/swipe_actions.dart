import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';

import '../theme/app_text_styles.dart';

/// One of the buttons [SwipeActionTile] reveals.
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });
}

/// A tile that slides left to reveal [actions] behind it, the way Telegram's
/// chat list does: let go past halfway and it stays open on them; keep
/// dragging and the last action — the one at the edge — stretches over the
/// rest, and runs on its own once let go. The actions are separate buttons
/// rounded like the tile, with a small gap between each and the tile.
class SwipeActionTile extends StatefulWidget {
  /// Left to right as they sit behind the tile; the last one is what a full
  /// swipe runs.
  final List<SwipeAction> actions;
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  /// Shared by a list's tiles, so opening one closes whichever was open.
  final ValueNotifier<Object?>? openTile;

  const SwipeActionTile({
    super.key,
    required this.actions,
    required this.child,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.openTile,
  });

  @override
  State<SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<SwipeActionTile>
    with TickerProviderStateMixin {
  static const _actionWidth = 84.0;

  /// Between the actions, and between the first of them and the tile.
  static const _gap = 8.0;

  /// How far across the tile a drag has to reach before letting go runs the
  /// last action instead of just leaving the actions open.
  static const _fullSwipeShare = 0.65;

  /// How much of the actions is showing, in pixels.
  late final _reveal = AnimationController.unbounded(vsync: this);

  /// 0 → 1 as a drag crosses into "full swipe": the other actions fold
  /// away and the last one takes the whole width.
  late final _armed = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  bool _isArmed = false;
  double _width = 0;

  /// Fully open: every action and the gap before it.
  double get _actionsWidth => (_actionWidth + _gap) * widget.actions.length;

  @override
  void initState() {
    super.initState();
    widget.openTile?.addListener(_onOpenTileChanged);
  }

  @override
  void didUpdateWidget(SwipeActionTile old) {
    super.didUpdateWidget(old);
    if (old.openTile != widget.openTile) {
      old.openTile?.removeListener(_onOpenTileChanged);
      widget.openTile?.addListener(_onOpenTileChanged);
    }
  }

  @override
  void dispose() {
    widget.openTile?.removeListener(_onOpenTileChanged);
    _reveal.dispose();
    _armed.dispose();
    super.dispose();
  }

  void _onOpenTileChanged() {
    if (widget.openTile?.value != this && _reveal.value > 0) _settle(0);
  }

  void _setArmed(bool armed) {
    if (armed == _isArmed) return;
    _isArmed = armed;
    if (armed) {
      HapticFeedback.mediumImpact();
      _armed.forward();
    } else {
      _armed.reverse();
    }
  }

  void _settle(double target) {
    _reveal.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (target == 0) {
      _setArmed(false);
      if (widget.openTile?.value == this) widget.openTile!.value = null;
    }
  }

  void _onDragStart(DragStartDetails _) {
    _reveal.stop();
    widget.openTile?.value = this;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_reveal.value - details.delta.dx).clamp(0.0, _width);
    _reveal.value = next;
    _setArmed(next > _actionsWidth && next > _width * _fullSwipeShare);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isArmed) {
      _run(widget.actions.last);
      return;
    }
    // Leftward flings open, rightward ones close; a slow release goes to
    // whichever it's nearer.
    final velocity = -(details.primaryVelocity ?? 0);
    final open = velocity.abs() > 300
        ? velocity > 0
        : _reveal.value > _actionsWidth / 2;
    _settle(open ? _actionsWidth : 0);
  }

  void _run(SwipeAction action) {
    action.onPressed();
    _settle(0);
  }

  void _onTap() {
    if (_reveal.value > 0) {
      _settle(0);
    } else {
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      customSemanticsActions: {
        for (final action in widget.actions)
          CustomSemanticsAction(label: action.label): action.onPressed,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return ClipRRect(
            borderRadius: widget.borderRadius,
            child: AnimatedBuilder(
              animation: Listenable.merge([_reveal, _armed]),
              builder: (context, child) {
                final reveal = _reveal.value;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _actionButtons(reveal),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(-reveal, 0),
                      child: child,
                    ),
                  ],
                );
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Each action takes a slot — the button and the gap before it. Up to
  /// their full width the slots share what's revealed evenly; past it the
  /// others keep theirs and the last one takes the rest — all of it, once
  /// armed.
  List<Widget> _actionButtons(double reveal) {
    final count = widget.actions.length;
    final slot = _actionWidth + _gap;
    final base = reveal <= _actionsWidth ? reveal / count : slot;
    final others = base * (1 - _armed.value);
    final last = reveal - others * (count - 1);
    return [
      for (var i = 0; i < count; i++)
        SizedBox(
          width: i == count - 1 ? last : others,
          child: Align(
            alignment: Alignment.centerRight,
            child: _ActionButton(
              action: widget.actions[i],
              width: max(0, (i == count - 1 ? last : others) - _gap),
              fullWidth: _actionWidth,
              borderRadius: widget.borderRadius,
              onTap: () => _run(widget.actions[i]),
            ),
          ),
        ),
    ];
  }
}

class _ActionButton extends StatelessWidget {
  final SwipeAction action;
  final double width;
  final double fullWidth;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const _ActionButton({
    required this.action,
    required this.width,
    required this.fullWidth,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Stretched past its own width, the content stays by the tile's edge,
    // following the drag, as Telegram's does.
    final stretched = width > fullWidth;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: action.color,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: stretched ? 0 : (width - fullWidth) / 2,
                width: fullWidth,
                child: Opacity(
                  opacity: (width / fullWidth).clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action.icon, size: 20, color: action.foreground),
                        const SizedBox(height: 4),
                        Text(
                          action.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: action.foreground,
                          ).copyWith(height: 1.15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
