import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/now_bar_bridge.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/settings_widgets.dart';

/// "Now Bar" on the phones that have one, "Persistent notification"
/// everywhere else — it's the same notification either way, only where the
/// system puts it differs (see NowBarStatus.isNowBar).
String nowBarTitle(AppLocalizations t, NowBarStatus status) =>
    status.isNowBar ? t.nowBarTitle : t.persistentNotifTitle;

/// The Now Bar / persistent notification settings: what it is, the switch,
/// and — when the phone itself is what's keeping it hidden — a way into the
/// system setting that is.
Future<void> showNowBarSheet(
  BuildContext context,
  AppState appState,
  NowBarStatus initial,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _NowBarSheet(appState: appState, initial: initial),
  );
}

class _NowBarSheet extends StatefulWidget {
  final AppState appState;
  final NowBarStatus initial;

  const _NowBarSheet({required this.appState, required this.initial});

  @override
  State<_NowBarSheet> createState() => _NowBarSheetState();
}

class _NowBarSheetState extends State<_NowBarSheet> {
  static const _bridge = NowBarBridge();

  late NowBarStatus _status = widget.initial;
  bool _busy = false;

  // Coming back from the system settings page this sheet links to is when
  // what it shows is most likely to have changed.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _reload);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final fresh = await _bridge.status();
    if (!mounted || fresh == null) return;
    setState(() => _status = fresh);
  }

  Future<void> _toggle(bool enabled) async {
    if (_busy) return;
    _busy = true;
    setState(() => _status = _status.copyWith(enabled: enabled));
    if (enabled && !_status.notificationsAllowed) {
      await widget.appState.notifications.requestNotificationsPermission();
    }
    await _bridge.setEnabled(enabled);
    await _reload();
    _busy = false;
  }

  Future<void> _toggleSchedule(bool show) async {
    setState(() => _status = _status.copyWith(showSchedule: show));
    await _bridge.setShowSchedule(show);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final muted = AppColors.text.withValues(alpha: 0.65);

    // Only one problem is shown at a time, the one that hides it outright
    // first: with notifications off, where it would show is beside the
    // point. Android's own per-app promotion setting isn't one of them — on
    // One UI it reads as refused even while the Now Bar shows the
    // notification; the developer switch is what actually decides there.
    final showDeveloperSwitch =
        _status.enabled &&
        _status.notificationsAllowed &&
        _status.needsDeveloperSwitch;
    final showNotificationsOff =
        _status.enabled && !_status.notificationsAllowed;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                nowBarTitle(t, _status),
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(fontSize: 18),
              ),
              const SizedBox(height: 10),
              SettingsRow(
                trailing: AppSwitch(value: _status.enabled, onChanged: _toggle),
                child: _LabelWithInfo(
                  label: _status.isNowBar
                      ? t.nowBarSwitchLabel
                      : t.persistentNotifSwitchLabel,
                  info: _status.isNowBar
                      ? t.nowBarDescription
                      : t.persistentNotifDescription,
                ),
              ),
              // The Now Bar's expanded card, or the plain notification's
              // expanded form everywhere else.
              if (_status.enabled) ...[
                SettingsRow(
                  trailing: AppSwitch(
                    value: _status.showSchedule,
                    onChanged: _toggleSchedule,
                  ),
                  child: _LabelWithInfo(
                    label: t.nowBarScheduleLabel,
                    info: _status.isNowBar
                        ? t.nowBarScheduleDescription
                        : t.nowBarScheduleDescriptionPlain,
                  ),
                ),
              ],
              if (showDeveloperSwitch) ...[
                const SizedBox(height: 16),
                NowBarDeveloperSwitchCard(status: _status),
              ],
              if (showNotificationsOff) ...[
                const SizedBox(height: 14),
                Text(
                  t.nowBarNotificationsOff,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: muted,
                  ).copyWith(height: 1.4),
                ),
                OptRow(
                  onTap: _bridge.openNotificationSettings,
                  child: Text(
                    t.nowBarOpenSettings,
                    style: AppTextStyles.body(
                      fontSize: 15,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A switch's name with an info button beside it. Tapping the button pops
/// a small bubble over it, pointing at it, with what the switch does — so
/// the explanations don't crowd the sheet itself. It goes away on any tap,
/// or by itself after a few seconds.
class _LabelWithInfo extends StatefulWidget {
  final String label;
  final String info;

  const _LabelWithInfo({required this.label, required this.info});

  @override
  State<_LabelWithInfo> createState() => _LabelWithInfoState();
}

class _LabelWithInfoState extends State<_LabelWithInfo> {
  final _iconKey = GlobalKey();
  OverlayEntry? _bubble;
  Timer? _autoHide;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  void _hide() {
    _autoHide?.cancel();
    _autoHide = null;
    _bubble?.remove();
    _bubble = null;
  }

  void _show() {
    _hide();
    final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final entry = OverlayEntry(
      builder: (_) =>
          _InfoBubble(anchor: anchor, text: widget.info, onDismiss: _hide),
    );
    Overlay.of(context).insert(entry);
    _bubble = entry;
    _autoHide = Timer(const Duration(seconds: 5), _hide);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Flexible(
          child: Text(widget.label, style: AppTextStyles.body(fontSize: 15)),
        ),
        Semantics(
          button: true,
          label: t.infoButtonLabel,
          hint: widget.info,
          child: InkResponse(
            key: _iconKey,
            onTap: () => _bubble == null ? _show() : _hide(),
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.info_outline_rounded,
                size: 19,
                color: AppColors.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The bubble [_LabelWithInfo] shows: in the app's icon colors (soft gold,
/// deep gold text — see IconBadge), above the icon with a small arrow pointing at it — or
/// below, when there's no room above.
class _InfoBubble extends StatelessWidget {
  final Rect anchor;
  final String text;
  final VoidCallback onDismiss;

  const _InfoBubble({
    required this.anchor,
    required this.text,
    required this.onDismiss,
  });

  static const _gap = 4.0;
  static const _arrowWidth = 14.0;
  static const _arrowHeight = 7.0;
  static const _margin = 16.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final color = AppColors.accent100;
    // Room enough above for a few lines of text; otherwise it opens below.
    final above = anchor.top - padding.top > 140;
    final arrowTop = above
        ? anchor.top - _gap - _arrowHeight
        : anchor.bottom + _gap;

    return Stack(
      children: [
        // Any tap elsewhere closes it, and still goes through. A tap on
        // the icon is left to the icon, which closes it itself.
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (!anchor.contains(event.position)) onDismiss();
            },
          ),
        ),
        Positioned(
          left: anchor.center.dx - _arrowWidth / 2,
          top: arrowTop,
          child: CustomPaint(
            size: const Size(_arrowWidth, _arrowHeight),
            painter: _ArrowPainter(color: color, pointsDown: above),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _BubbleLayout(
            anchorX: anchor.center.dx,
            // Overlaps the arrow by a pixel so the two read as one shape.
            edgeY: above ? arrowTop + 1 : arrowTop + _arrowHeight - 1,
            above: above,
            margin: _margin,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screen.width - _margin * 2),
            // Material gives the text its default style: straight in the
            // overlay it had none, and Flutter underlined it in yellow.
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  style: AppTextStyles.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent700,
                  ).copyWith(height: 1.35),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Places the bubble against [edgeY] (its bottom when [above], its top
/// otherwise), centered on [anchorX] as far as the screen edges allow.
class _BubbleLayout extends SingleChildLayoutDelegate {
  final double anchorX;
  final double edgeY;
  final bool above;
  final double margin;

  const _BubbleLayout({
    required this.anchorX,
    required this.edgeY,
    required this.above,
    required this.margin,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = size.width - margin - childSize.width;
    final left = (anchorX - childSize.width / 2).clamp(
      margin,
      maxLeft < margin ? margin : maxLeft,
    );
    final top = above ? edgeY - childSize.height : edgeY;
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_BubbleLayout old) =>
      old.anchorX != anchorX || old.edgeY != edgeY || old.above != above;
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointsDown;

  const _ArrowPainter({required this.color, required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final path = pointsDown
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height))
        : (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width, size.height)
            ..lineTo(size.width / 2, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.pointsDown != pointsDown;
}

/// The step-by-step way to One UI's "Live notifications for all apps"
/// developer switch, for a phone that has a Now Bar but keeps this app out
/// of it until that switch is on. Starts from unlocking developer options
/// when they haven't been yet, and ends in a button straight to the page
/// the next step is on.
class NowBarDeveloperSwitchCard extends StatelessWidget {
  final NowBarStatus status;

  const NowBarDeveloperSwitchCard({super.key, required this.status});

  static const _bridge = NowBarBridge();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final unlocked = status.developerOptionsEnabled;
    final steps = [
      if (!unlocked) ...[t.nowBarDevStepAbout, t.nowBarDevStepBuildNumber],
      t.nowBarDevStepDeveloperOptions,
      t.nowBarDevStepSwitch,
    ];
    final textStyle = AppTextStyles.body(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: AppColors.text.withValues(alpha: 0.8),
    ).copyWith(height: 1.4);

    // The app's icon colors (see IconBadge) for the step numbers and the
    // button: soft gold behind, deep gold on top, in either theme.
    final badgeBg = AppColors.accent100;
    final badgeFg = AppColors.accent700;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.priority_high_rounded,
                  size: 17,
                  color: AppColors.accent700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.nowBarDevTitle,
                  style: AppTextStyles.heading(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.nowBarDevBody, style: textStyle),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(steps[i], style: textStyle)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: unlocked
                ? _bridge.openDeveloperSettings
                : _bridge.openDeviceInfo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unlocked ? t.nowBarDevOpenDeveloper : t.nowBarDevOpenAbout,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: badgeFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
