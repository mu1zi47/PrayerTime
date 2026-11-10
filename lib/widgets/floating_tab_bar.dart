import 'app_tap.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _TabSpec {
  final IconData icon;
  final String label;

  const _TabSpec(this.icon, this.label);
}

List<_TabSpec> _tabs(AppLocalizations t) => [
  _TabSpec(Icons.home_rounded, t.navPrayer),
  _TabSpec(Icons.grid_view_rounded, t.navMore),
  _TabSpec(Icons.tune_rounded, t.navSettings),
];

/// A floating, pill-shaped nav bar in the style of Samsung One UI 8.5/9 —
/// detached from the screen edge, glassy/blurred, with a filled capsule
/// that morphs to the selected tab instead of a fixed underline/bar.
class FloatingTabBar extends StatefulWidget {
  static const surfaceKey = ValueKey('floating-tab-bar-surface');
  static const _buttonVerticalPadding = 12.0;
  static const _surfacePadding = 6.0;
  static const _borderWidth = 1.0;
  static const _minimumBottom = 16.0;
  static const _iconSize = 20.0;

  /// Includes the actual label height at the user's text size, safe area,
  /// and the same 16px gap used between the app's panels.
  static double contentBottomInset(BuildContext context) {
    final label = TextPainter(
      text: TextSpan(
        text: ' ',
        style: DefaultTextStyle.of(context).style.merge(
          AppTextStyles.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final rowHeight = math.max(_iconSize, label.height);
    label.dispose();
    return rowHeight +
        2 * (_buttonVerticalPadding + _surfacePadding + _borderWidth) +
        math.max(_minimumBottom, MediaQuery.paddingOf(context).bottom) +
        16;
  }

  final int index;
  final ValueChanged<int> onSelect;

  const FloatingTabBar({
    super.key,
    required this.index,
    required this.onSelect,
  });

  @override
  State<FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<FloatingTabBar> {
  final _rowKey = GlobalKey();
  final _tabKeys = List.generate(3, (_) => GlobalKey());
  List<Rect>? _targets;
  Offset _start = Offset.zero;
  Offset _origin = Offset.zero;
  Rect? _capsule;
  int? _target;
  int _source = 0;
  int _layoutIndex = 0;
  bool _pickup = false;

  void _startDrag(Offset position) {
    final targets = [
      for (final key in _tabKeys)
        if (key.currentContext?.findRenderObject() case final RenderBox box)
          box.localToGlobal(Offset.zero) & box.size,
    ];
    final pressed = targets.indexWhere((rect) => rect.contains(position));
    if (targets.length != 3 || pressed < 0) {
      return;
    }
    final row = _rowKey.currentContext!.findRenderObject()! as RenderBox;
    HapticFeedback.mediumImpact();
    setState(() {
      _targets = targets;
      _layoutIndex = widget.index;
      _source = pressed;
      _target = pressed;
      _pickup = pressed != widget.index;
      _start = position;
      _origin = row.localToGlobal(Offset.zero);
      _capsule = targets[widget.index];
    });
    if (pressed != widget.index) {
      widget.onSelect(pressed);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_targets, targets) || !_pickup) return;
        setState(() => _capsule = targets[pressed]);
      });
    }
  }

  void _moveDrag(Offset position) {
    final targets = _targets;
    if (targets == null) return;
    final ordered = [...targets]
      ..sort((a, b) => a.center.dx.compareTo(b.center.dx));
    final center = targets[_source].center.dx + position.dx - _start.dx;
    var capsule = center < ordered.first.center.dx
        ? ordered.first
        : ordered.last;
    for (var i = 0; i < ordered.length - 1; i++) {
      final left = ordered[i];
      final right = ordered[i + 1];
      if (center >= left.center.dx && center <= right.center.dx) {
        capsule = Rect.lerp(
          left,
          right,
          (center - left.center.dx) / (right.center.dx - left.center.dx),
        )!;
        break;
      }
    }
    var target = _source;
    var distance = double.infinity;
    for (var i = 0; i < targets.length; i++) {
      final d = (targets[i].center.dx - position.dx).abs();
      if (d < distance) {
        target = i;
        distance = d;
      }
    }
    if (target != _target) HapticFeedback.selectionClick();
    setState(() {
      _pickup = false;
      _capsule = capsule;
      _target = target;
    });
  }

  void _finishDrag({bool cancel = false}) {
    if (_targets == null) return;
    final target = _target;
    setState(() {
      _pickup = false;
      _targets = null;
      _capsule = null;
      _target = null;
    });
    if (!cancel && target != null && target != widget.index) {
      widget.onSelect(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final tabs = _tabs(AppLocalizations.of(context)!);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: FloatingTabBar._minimumBottom),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: BackdropFilter(
              // Real-time blur is one of the more expensive things a frame
              // can do (especially on Impeller, Android's default rendering
              // backend as of this Flutter version) and this bar sits over
              // content that's constantly changing during tab transitions —
              // a much smaller sigma keeps the glassy look while cutting
              // that per-frame cost substantially.
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                key: FloatingTabBar.surfaceKey,
                padding: const EdgeInsets.all(FloatingTabBar._surfacePadding),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.text.withValues(alpha: 0.1),
                    width: FloatingTabBar._borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neutral900.withValues(alpha: 0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Listener(
                  onPointerDown: (_) => HapticFeedback.lightImpact(),
                  onPointerCancel: (_) => _finishDrag(cancel: true),
                  child: AppTap(
                    feedbackOnChild: false,
                    onLongPressStart: (d) => _startDrag(d.globalPosition),
                    onLongPressMoveUpdate: (d) => _moveDrag(d.globalPosition),
                    onLongPressEnd: (_) => _finishDrag(),
                    onLongPressCancel: () => _finishDrag(cancel: true),
                    child: Stack(
                      children: [
                        if (_capsule case final Rect capsule)
                          AnimatedPositioned.fromRect(
                            duration: _pickup
                                ? const Duration(milliseconds: 220)
                                : Duration.zero,
                            curve: Curves.easeOutCubic,
                            rect: capsule.shift(-_origin),
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: const ValueKey("tab-drag-capsule"),
                                decoration: BoxDecoration(
                                  gradient: AppColors.selectionGradient,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        AppPressContent(
                          child: Row(
                            key: _rowKey,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < tabs.length; i++)
                                _FloatingTabButton(
                                  key: _tabKeys[i],
                                  spec: tabs[i],
                                  selected:
                                      i ==
                                      (_targets != null
                                          ? _layoutIndex
                                          : widget.index),
                                  dragging: _targets != null,
                                  highlighted: i == (_target ?? widget.index),
                                  onTap: () => widget.onSelect(i),
                                ),
                            ],
                          ),
                        ),
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

class _FloatingTabButton extends StatelessWidget {
  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final bool dragging;
  final bool highlighted;

  const _FloatingTabButton({
    super.key,
    required this.dragging,
    required this.highlighted,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    // Semantic colors interpolate across the reversed light/dark ramps.
    final onFill = AppColors.onControlFill;
    return AppTap(
      feedbackOnChild: false,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: dragging ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 20 : 16,
          vertical: FloatingTabBar._buttonVerticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: selected && !dragging ? AppColors.selectionGradient : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: AppPressContent(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                spec.icon,
                size: 20,
                color: highlighted
                    ? onFill
                    : AppColors.text.withValues(alpha: 0.55),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          spec.label,
                          style: AppTextStyles.body(
                            fontSize: 13,
                            color: highlighted ? onFill : AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
