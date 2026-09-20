import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/notif_mode.dart';
import '../state/app_state.dart';
import '../widgets/icon_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_switch.dart';
import '../widgets/notif_mode_selector.dart';
import '../widgets/prayer_icon.dart';
import '../widgets/settings_widgets.dart';

/// Opens notification settings as a modal sheet rather than a pushed full
/// screen — a fairly short, self-contained block of toggles doesn't need a
/// screen of its own (same idea as showChoiceSheet, just for a denser
/// group of settings instead of a single pick-one list).
Future<void> showNotificationsSheet(BuildContext context, AppState appState) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _NotificationsSheet(appState: appState),
  );
}

class _NotificationsSheet extends StatelessWidget {
  final AppState appState;

  const _NotificationsSheet({required this.appState});

  static const _notifOrder = [
    ('fajr', PrayerKind.fajr),
    ('zuhr', PrayerKind.zuhr),
    ('asr', PrayerKind.asr),
    ('maghrib', PrayerKind.maghrib),
    ('isha', PrayerKind.isha),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final t = AppLocalizations.of(context)!;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                  t.notificationsScreenTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(fontSize: 18),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsGroup(
                          kicker: t.azanByPrayersKicker,
                          children: [
                            for (final (key, kind) in [
                              if (appState.tahajjudEnabled)
                                ('tahajjud', PrayerKind.tahajjud),
                              ..._notifOrder,
                            ])
                              SettingsRow(
                                trailing: NotifModeSelector(
                                  value:
                                      appState.notifMode[key] ??
                                      NotifMode.notification,
                                  onChanged: (mode) =>
                                      appState.setNotifMode(key, mode),
                                ),
                                child: Row(
                                  children: [
                                    IconBadge(
                                      iconForPrayer(kind),
                                      size: 32,
                                      iconSize: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      nameForPrayer(t, kind),
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
                              child: Text(
                                t.dontDisturbNight,
                                style: AppTextStyles.body(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
