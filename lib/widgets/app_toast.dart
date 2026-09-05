import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A floating, stackable toast notification.
///
/// Shows near the bottom of the screen, flies in, auto-dismisses after a
/// few seconds, and can be swiped away left/right/down at any time (up is
/// intentionally excluded — see [_ToastCardState._onPanUpdate]). Calling
/// [show] more than once stacks toasts: the newest always lands in the
/// bottom slot and older ones shift up to make room.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static final GlobalKey<_ToastHostState> _hostKey =
      GlobalKey<_ToastHostState>();

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (_entry == null) {
      final overlay = Overlay.of(context, rootOverlay: true);
      final entry = OverlayEntry(builder: (_) => _ToastHost(key: _hostKey));
      _entry = entry;
      overlay.insert(entry);
      // The entry's State doesn't exist synchronously on the very first
      // insert — only from the next frame on. Later calls skip this since
      // the host stays mounted for the app's lifetime.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _hostKey.currentState?.addToast(message, icon);
      });
    } else {
      _hostKey.currentState?.addToast(message, icon);
    }
  }
}

class _ToastData {
  final int id;
  final String message;
  final IconData icon;

  const _ToastData({
    required this.id,
    required this.message,
    required this.icon,
  });
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({super.key});

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  final List<_ToastData> _toasts = [];
  int _nextId = 0;

  void addToast(String message, IconData icon) {
    setState(() {
      _toasts.add(_ToastData(id: _nextId++, message: message, icon: icon));
    });
  }

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _toasts.removeWhere((t) => t.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset + 16,
      child: IgnorePointer(
        ignoring: _toasts.isEmpty,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final toast in _toasts)
                  Padding(
                    key: ValueKey(toast.id),
                    padding: const EdgeInsets.only(top: 8),
                    child: _ToastCard(
                      data: toast,
                      onDismiss: () => _remove(toast.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  final _ToastData data;
  final VoidCallback onDismiss;

  const _ToastCard({required this.data, required this.onDismiss});

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  static const _autoDismissAfter = Duration(seconds: 4);
  static const _horizontalDismissDistance = 90.0;
  static const _downDismissDistance = 70.0;
  static const _flingVelocity = 650.0;

  late final AnimationController _enterController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  late final AnimationController _dragController;
  Animation<Offset>? _dragAnimation;

  Offset _dragOffset = Offset.zero;
  Timer? _autoDismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _fade = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
        );

    _dragController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          final anim = _dragAnimation;
          if (anim != null) setState(() => _dragOffset = anim.value);
        });

    _autoDismissTimer = Timer(_autoDismissAfter, _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _enterController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _dismiss([Offset flyTo = const Offset(0, 60)]) {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    _animateTo(flyTo, then: widget.onDismiss);
  }

  void _animateTo(Offset target, {VoidCallback? then}) {
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _dragController, curve: Curves.easeOut));
    _dragController
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) then?.call();
      });
  }

  void _onPanStart(DragStartDetails details) {
    _autoDismissTimer?.cancel();
    _dragController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      var dy = _dragOffset.dy + details.delta.dy;
      // Swiping up is not a dismiss gesture — heavily resist it so the card
      // just rubber-bands instead of flying off the top.
      if (dy < 0) dy *= 0.25;
      _dragOffset = Offset(_dragOffset.dx + details.delta.dx, dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dismissed) return;
    final velocity = details.velocity.pixelsPerSecond;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    final horizontalFling = velocity.dx.abs() > _flingVelocity;
    final downFling = velocity.dy > _flingVelocity;
    final horizontalDrag = dx.abs() > _horizontalDismissDistance;
    final downDrag = dy > _downDismissDistance;

    if (horizontalFling || horizontalDrag) {
      final direction = (horizontalFling ? velocity.dx : dx) > 0 ? 1.0 : -1.0;
      _dismiss(Offset(direction * 500, dy));
      return;
    }
    if (downFling || downDrag) {
      _dismiss(Offset(dx, 300));
      return;
    }
    _animateTo(Offset.zero);
    _autoDismissTimer = Timer(_autoDismissAfter, _dismiss);
  }

  @override
  Widget build(BuildContext context) {
    final dragDistance = _dragOffset.distance;
    final dragOpacity = (1 - dragDistance / 180).clamp(0.0, 1.0);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Opacity(
              opacity: dragOpacity,
              child: _ToastCardVisual(
                icon: widget.data.icon,
                message: widget.data.message,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCardVisual extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ToastCardVisual({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        // The overlay entry sits outside any Scaffold/Material ancestor —
        // without this, Text below renders with debug mode's "no Material
        // ancestor" warning (a double yellow underline).
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neutral900.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: AppColors.accent700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.body(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
