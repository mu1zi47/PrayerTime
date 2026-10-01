import 'package:flutter/material.dart';

/// Shows [child] while [visible], opening it downwards from nothing and
/// fading it in — and folding it away the same way. Whatever holds it
/// resizes along with it frame by frame, so a bottom sheet sized to its
/// content grows and shrinks smoothly instead of jumping.
class ExpandReveal extends StatelessWidget {
  final bool visible;
  final Widget child;

  const ExpandReveal({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          // The content only fades in once there's some room for it.
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1),
          ),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: visible
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const SizedBox(key: ValueKey(false), width: double.infinity),
    );
  }
}
