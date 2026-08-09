import 'package:flutter/material.dart';

import '../models/app_locale.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/segmented_control.dart';
import '../widgets/settings_widgets.dart';
import 'city_screen.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';

/// Ported from the "Настройки" screen in the design.
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
        return ListView(
          padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
          children: [
            Text('Настройки', style: AppTextStyles.heading(fontSize: 22)),
            const SizedBox(height: 16),
            SettingsGroup(
              kicker: 'Город',
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CityScreen(appState: appState)),
                  ),
                  child: Text(appState.selectedCity, style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: 'Мазхаб (расчёт Аср)',
              children: [
                SegmentedControl(
                  options: const ['Шафии', 'Ханафи'],
                  selectedIndex: appState.madhab == 'shafi' ? 0 : 1,
                  onSelect: (i) => appState.selectMadhab(i == 0 ? 'shafi' : 'hanafi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: 'Язык',
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
              kicker: 'Тема',
              children: [
                SegmentedControl(
                  options: const ['Светлая', 'Тёмная', 'Системная'],
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
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: 'Уведомления',
              children: [
                OptRow(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen(appState: appState)),
                  ),
                  child: Text('Азан и напоминания', style: AppTextStyles.body(fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              kicker: 'Now Bar',
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 2),
                  child: Text(
                    'Доступно только на Samsung с One UI 7 и выше',
                    style: AppTextStyles.body(fontSize: 12, color: AppColors.text).copyWith(
                      color: AppColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (appState.nowBarSupported) ...[
                  SettingsRow(
                    trailing: AppSwitch(
                      value: appState.nowBarCurrentPrayer,
                      onChanged: (_) => appState.toggleNowBarCurrentPrayer(),
                    ),
                    child: Text('Показывать текущий намаз', style: AppTextStyles.body(fontSize: 15)),
                  ),
                  SettingsRow(
                    trailing: AppSwitch(
                      value: appState.nowBarNextPrayer,
                      onChanged: (_) => appState.toggleNowBarNextPrayer(),
                    ),
                    child: Text('Показывать следующий намаз', style: AppTextStyles.body(fontSize: 15)),
                  ),
                  if (!appState.nowBarPermissionGranted)
                    OptRow(
                      onTap: () => appState.openNowBarSettings(),
                      background: AppColors.accent100,
                      child: Text(
                        'Разрешить показ в Now Bar',
                        style: AppTextStyles.body(fontSize: 15, color: AppColors.accent700, fontWeight: FontWeight.w700),
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Ваше устройство не поддерживается',
                      style: AppTextStyles.body(fontSize: 13, color: AppColors.accent700),
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
