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
              const SizedBox(height: 14),
              Text(
                _status.isNowBar
                    ? t.nowBarDescription
                    : t.persistentNotifDescription,
                style: AppTextStyles.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: muted,
                ).copyWith(height: 1.4),
              ),
              const SizedBox(height: 10),
              SettingsRow(
                trailing: AppSwitch(value: _status.enabled, onChanged: _toggle),
                child: Text(
                  t.nowBarSwitchLabel,
                  style: AppTextStyles.body(fontSize: 15),
                ),
              ),
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

    // The same two gold tones as the app's icon badges and selected tab,
    // arranged so the badge and button are always the deep one.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final deep = dark ? AppColors.accent100 : AppColors.accent700;
    final soft = dark ? AppColors.accent700 : AppColors.accent100;

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
                      color: deep,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: soft,
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
                color: deep,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unlocked ? t.nowBarDevOpenDeveloper : t.nowBarDevOpenAbout,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: soft,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
