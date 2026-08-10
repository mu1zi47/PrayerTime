import 'package:flutter/material.dart';

import '../data/azan_sounds.dart';
import '../l10n/app_localizations.dart';
import '../models/notif_mode.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/notif_mode_selector.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/screen_back_button.dart';
import '../widgets/settings_widgets.dart';
import 'azan_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final AppState appState;

  const NotificationsScreen({super.key, required this.appState});

  static const _notifOrder = [
    ('fajr', PrayerKind.fajr),
    ('zuhr', PrayerKind.zuhr),
    ('asr', PrayerKind.asr),
    ('maghrib', PrayerKind.maghrib),
    ('isha', PrayerKind.isha),
  ];

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
                    Text(t.notificationsScreenTitle, style: AppTextStyles.heading(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  kicker: t.azanByPrayersKicker,
                  children: [
                    for (final (key, kind) in _notifOrder)
                      SettingsRow(
                        trailing: NotifModeSelector(
                          value: appState.notifMode[key] ?? NotifMode.azan,
                          onChanged: (mode) => appState.setNotifMode(key, mode),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.bg, shape: BoxShape.circle),
                              child: Icon(iconForPrayer(kind), size: 16, color: AppColors.accent700),
                            ),
                            const SizedBox(width: 10),
                            Text(nameForPrayer(t, kind), style: AppTextStyles.body(fontSize: 15)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsGroup(
                  kicker: t.soundKicker,
                  children: [
                    OptRow(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AzanScreen(appState: appState)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, size: 16, color: AppColors.text),
                          const SizedBox(width: 10),
                          Text(
                            t.azanSoundRow(reciterNameFor(t, appState.azanSoundId)),
                            style: AppTextStyles.body(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SettingsGroup(
                  kicker: t.quietKicker,
                  children: [
                    SettingsRow(
                      trailing: AppSwitch(
                        value: appState.quiet,
                        onChanged: (_) => appState.toggleQuiet(),
                      ),
                      child: Text(t.dontDisturbNight, style: AppTextStyles.body(fontSize: 15)),
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
