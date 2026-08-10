import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../models/app_locale.dart';
import '../state/app_state.dart';
import '../theme/app_text_styles.dart';
import '../widgets/segmented_control.dart';
import '../widgets/settings_widgets.dart';
import 'city_screen.dart';
import 'language_screen.dart';
import 'method_screen.dart';
import 'notifications_screen.dart';
import 'now_bar_screen.dart';

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
            Text(t.settingsScreenTitle, style: AppTextStyles.heading(fontSize: 22)),
            const SizedBox(height: 16),
            SettingsGroup(
              kicker: t.cityKicker,
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CityScreen(appState: appState)),
                  ),
                  child: Text(cityNameFor(t, appState.selectedCityId), style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: t.methodScreenTitle,
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MethodScreen(appState: appState)),
                  ),
                  child: Text(appState.methodLabel, style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: t.madhabKicker,
              children: [
                SegmentedControl(
                  options: [t.madhabShafi, t.madhabHanafi],
                  selectedIndex: appState.madhab == 'shafi' ? 0 : 1,
                  onSelect: (i) => appState.selectMadhab(i == 0 ? 'shafi' : 'hanafi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: t.notificationsScreenTitle,
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen(appState: appState)),
                  ),
                  child: Text(t.azanAndReminders, style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            // Samsung One UI 7+ only — hidden entirely elsewhere rather than
            // shown disabled, since it'd otherwise be dead UI for the vast
            // majority of devices (see AppState.nowBarSupported).
            if (appState.nowBarSupported) ...[
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.nowBarScreenTitle,
                children: [
                  OptRow(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => NowBarScreen(appState: appState)),
                    ),
                    child: Text(t.nowBarSettingsRow, style: AppTextStyles.body(fontSize: 15)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: t.languageScreenTitle,
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LanguageScreen(appState: appState)),
                  ),
                  child: Text(appState.locale.label, style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: t.themeKicker,
              children: [
                SegmentedControl(
                  options: [t.themeLight, t.themeDark, t.themeSystem],
                  selectedIndex: switch (appState.themeMode) {
                    ThemeMode.light => 0,
                    ThemeMode.dark => 1,
                    ThemeMode.system => 2,
                  },
                  onSelect: (i) => appState.setThemeMode(
                    switch (i) {
                      0 => ThemeMode.light,
                      1 => ThemeMode.dark,
                      _ => ThemeMode.system,
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
