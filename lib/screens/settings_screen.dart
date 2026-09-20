import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/icon_badge.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_toast.dart';
import '../widgets/settings_widgets.dart';
import 'prayer_settings_screen.dart';
import 'system_settings_screen.dart';

const _feedbackEmail = 'valiyevmuiz0407@gmail.com';
const _feedbackTelegram = '@ThePr0bl3m';
const _telegramHandle = 'ThePr0bl3m';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  /// Tries each URI in turn and falls back to the clipboard if none of them
  /// opens anything — a phone with no mail app set up, or without Telegram,
  /// would otherwise just swallow the tap.
  ///
  /// The order matters for Telegram: `tg://` opens the app itself, while
  /// `https://t.me/…` is only a web link, so unless Telegram has claimed
  /// that domain it lands in a browser instead.
  Future<void> _open(
    BuildContext context,
    List<Uri> uris,
    String contact,
  ) async {
    var launched = false;
    for (final uri in uris) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
      if (launched) break;
    }
    if (launched || !context.mounted) return;

    final t = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: contact));
    if (!context.mounted) return;
    AppToast.show(
      context,
      '${t.feedbackCopied}: $contact',
      icon: Icons.copy_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    // No SafeArea — see HomeScreen's build() for why: content should scroll
    // edge-to-edge, under the transparent status bar, not stop short of it.
    final topInset = MediaQuery.paddingOf(context).top;
    final t = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, topInset + 16, 18, 130),
      children: [
        Text(t.settingsScreenTitle, style: AppTextStyles.heading(fontSize: 22)),
        const SizedBox(height: 16),
        OptRow(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PrayerSettingsScreen(appState: appState),
            ),
          ),
          child: Row(
            children: [
              const IconBadge(Icons.access_time_rounded),
              const SizedBox(width: 12),
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
              const IconBadge(Icons.tune_rounded),
              const SizedBox(width: 12),
              Text(
                t.systemSettingsTitle,
                style: AppTextStyles.body(fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SettingsGroup(
          kicker: t.feedbackKicker,
          children: [
            _ContactRow(
              icon: Icons.mail_outline_rounded,
              label: t.feedbackEmail,
              contact: _feedbackEmail,
              onTap: () => _open(context, [
                Uri(
                  scheme: 'mailto',
                  path: _feedbackEmail,
                  queryParameters: const {'subject': 'Prayer times'},
                ),
              ], _feedbackEmail),
            ),
            _ContactRow(
              icon: Icons.send_rounded,
              label: t.feedbackTelegram,
              contact: _feedbackTelegram,
              onTap: () => _open(context, [
                Uri.parse('tg://resolve?domain=$_telegramHandle'),
                Uri.parse('https://t.me/$_telegramHandle'),
              ], _feedbackTelegram),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _AppVersion(),
      ],
    );
  }
}

/// The installed version, at the very bottom — the first thing to ask for
/// when someone writes in through the feedback rows above. Read from the
/// platform (pubspec's `version` as built), so it can't drift from what the
/// phone's own app info says.
class _AppVersion extends StatelessWidget {
  const _AppVersion();

  static final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        final t = AppLocalizations.of(context)!;
        return Center(
          child: Text(
            t.appVersionLabel(info.version),
            style: AppTextStyles.body(
              fontSize: 12.5,
              color: AppColors.text.withValues(alpha: 0.45),
            ),
          ),
        );
      },
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String contact;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OptRow(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body(fontSize: 15))),
          Text(
            contact,
            style: AppTextStyles.body(
              fontSize: 12.5,
              color: AppColors.text,
            ).copyWith(color: AppColors.text.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
