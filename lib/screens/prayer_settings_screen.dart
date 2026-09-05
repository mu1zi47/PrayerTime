import 'package:flutter/material.dart';

import '../data/reference_data.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/app_toast.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/settings_widgets.dart';
import 'city_screen.dart';

class PrayerSettingsScreen extends StatelessWidget {
  final AppState appState;

  const PrayerSettingsScreen({super.key, required this.appState});

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
                    t.prayerSettingsTitle,
                    style: AppTextStyles.heading(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SettingsGroup(
                kicker: t.cityKicker,
                children: [
                  OptRow(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CityScreen(appState: appState),
                      ),
                    ),
                    child: Text(
                      appState.cityLabel(t),
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.methodScreenTitle,
                children: [
                  OptRow(
                    onTap: () => showChoiceSheet(
                      context,
                      title: t.methodScreenTitle,
                      options: [
                        for (final m in ReferenceData.methods)
                          ChoiceSheetOption(label: methodLabelFor(t, m.id)),
                      ],
                      selectedIndex: ReferenceData.methods.indexWhere(
                        (m) => m.id == appState.method,
                      ),
                      onSelect: (i) async {
                        final applied = await appState.selectMethod(
                          ReferenceData.methods[i].id,
                        );
                        if (!context.mounted || applied) return;
                        AppToast.show(
                          context,
                          t.errorOfflineSettingsChange,
                          icon: Icons.wifi_off_rounded,
                        );
                      },
                    ),
                    child: Text(
                      appState.methodLabel,
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.madhabKicker,
                children: [
                  OptRow(
                    onTap: () => showChoiceSheet(
                      context,
                      title: t.madhabKicker,
                      options: [
                        ChoiceSheetOption(label: t.madhabShafi),
                        ChoiceSheetOption(label: t.madhabHanafi),
                      ],
                      selectedIndex: appState.madhab == 'shafi' ? 0 : 1,
                      onSelect: (i) async {
                        final applied = await appState.selectMadhab(
                          i == 0 ? 'shafi' : 'hanafi',
                        );
                        if (!context.mounted || applied) return;
                        AppToast.show(
                          context,
                          t.errorOfflineSettingsChange,
                          icon: Icons.wifi_off_rounded,
                        );
                      },
                    ),
                    child: Text(
                      appState.madhab == 'shafi' ? t.madhabShafi : t.madhabHanafi,
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SettingsGroup(
                kicker: t.tahajjudKicker,
                children: [
                  SettingsRow(
                    trailing: AppSwitch(
                      value: appState.tahajjudEnabled,
                      onChanged: (_) => appState.toggleTahajjud(),
                    ),
                    child: Text(
                      t.tahajjudEnableRow,
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
