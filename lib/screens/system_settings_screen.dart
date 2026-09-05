import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/settings_widgets.dart';
import 'notifications_screen.dart';

class SystemSettingsScreen extends StatelessWidget {
  final AppState appState;

  const SystemSettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status/navigation bars.
    final padding = MediaQuery.paddingOf(context);
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              padding.top + 16,
              18,
              padding.bottom + 18,
            ),
            children: [
              Row(
                children: [
                  ScreenBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text(
                    t.systemSettingsTitle,
                    style: AppTextStyles.heading(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                kicker: t.notificationsScreenTitle,
                children: [
                  OptRow(
                    onTap: () => showNotificationsSheet(context, appState),
                    child: Text(
                      t.azanAndReminders,
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.languageScreenTitle,
                children: [
                  OptRow(
                    onTap: () => showChoiceSheet(
                      context,
                      title: t.languageScreenTitle,
                      options: [
                        for (final l in AppLocale.values)
                          ChoiceSheetOption(label: l.label),
                      ],
                      selectedIndex: AppLocale.values.indexOf(appState.locale),
                      onSelect: (i) =>
                          appState.setLocale(AppLocale.values[i]),
                    ),
                    child: Text(
                      appState.locale.label,
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.themeKicker,
                children: [
                  OptRow(
                    onTap: () => showChoiceSheet(
                      context,
                      title: t.themeKicker,
                      options: [
                        ChoiceSheetOption(
                          label: t.themeLight,
                          icon: Icons.light_mode_rounded,
                        ),
                        ChoiceSheetOption(
                          label: t.themeDark,
                          icon: Icons.dark_mode_rounded,
                        ),
                        ChoiceSheetOption(
                          label: t.themeSystem,
                          icon: Icons.brightness_auto_rounded,
                        ),
                      ],
                      selectedIndex: switch (appState.themeMode) {
                        ThemeMode.light => 0,
                        ThemeMode.dark => 1,
                        ThemeMode.system => 2,
                      },
                      onSelect: (i) => appState.setThemeMode(switch (i) {
                        0 => ThemeMode.light,
                        1 => ThemeMode.dark,
                        _ => ThemeMode.system,
                      }),
                    ),
                    child: Text(
                      switch (appState.themeMode) {
                        ThemeMode.light => t.themeLight,
                        ThemeMode.dark => t.themeDark,
                        ThemeMode.system => t.themeSystem,
                      },
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
