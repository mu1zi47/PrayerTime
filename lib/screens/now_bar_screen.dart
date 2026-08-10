import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/settings_widgets.dart';

/// Settings for Samsung's "Now Bar" (One UI 7+'s Dynamic-Island-style
/// surface for ongoing notifications), pushed from [SettingsScreen]'s
/// single "Now Bar" row — only reachable at all on a device where
/// [AppState.nowBarSupported] is true (see that row's own guard).
class NowBarScreen extends StatelessWidget {
  final AppState appState;

  const NowBarScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status/navigation bars.
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final t = AppLocalizations.of(context)!;
          return ListView(
            padding: EdgeInsets.fromLTRB(18, padding.top + 16, 18, padding.bottom + 18),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text(t.nowBarScreenTitle, style: AppTextStyles.heading(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  t.nowBarAvailability,
                  style: AppTextStyles.body(fontSize: 13, color: AppColors.text).copyWith(
                    color: AppColors.text.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                kicker: t.nowBarScreenTitle,
                children: [
                  SettingsRow(
                    trailing: AppSwitch(
                      value: appState.nowBarCurrentPrayer,
                      onChanged: (_) => appState.toggleNowBarCurrentPrayer(),
                    ),
                    child: Text(t.nowBarShowCurrent, style: AppTextStyles.body(fontSize: 15)),
                  ),
                  SettingsRow(
                    trailing: AppSwitch(
                      value: appState.nowBarNextPrayer,
                      onChanged: (_) => appState.toggleNowBarNextPrayer(),
                    ),
                    child: Text(t.nowBarShowNext, style: AppTextStyles.body(fontSize: 15)),
                  ),
                  if (!appState.nowBarPermissionGranted)
                    OptRow(
                      onTap: () => appState.openNowBarSettings(),
                      background: AppColors.accent100,
                      child: Text(
                        t.nowBarAllowPermission,
                        style: AppTextStyles.body(fontSize: 15, color: AppColors.accent700, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
