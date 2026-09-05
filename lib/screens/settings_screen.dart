import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/settings_widgets.dart';
import 'prayer_settings_screen.dart';
import 'system_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status bar, not stop short of it.
    final topInset = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        return ListView(
          padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
          children: [
            Text(
              t.settingsScreenTitle,
              style: AppTextStyles.heading(fontSize: 22),
            ),
            const SizedBox(height: 16),
            OptRow(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PrayerSettingsScreen(appState: appState),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: AppColors.accent700,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.prayerSettingsTitle,
                    style: AppTextStyles.body(fontSize: 15),
                  ),
                ],
              ),
            ),
            OptRow(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SystemSettingsScreen(appState: appState),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.accent700,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.systemSettingsTitle,
                    style: AppTextStyles.body(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
