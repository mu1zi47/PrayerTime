import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum NotifMode {
  /// Announced with sound.
  notification,

  /// Still posted, just silently.
  silent,

  /// Not scheduled at all — see NotificationService.scheduleForDays, which
  /// skips both the prayer itself and its end-of-window reminder.
  off;

  static NotifMode fromName(String? name) => NotifMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => NotifMode.notification,
  );
}

extension NotifModeStyle on NotifMode {
  IconData get icon => switch (this) {
    NotifMode.notification => Icons.volume_up_rounded,
    NotifMode.silent => Icons.volume_off_rounded,
    NotifMode.off => Icons.notifications_off_rounded,
  };
}

String notifModeLabel(AppLocalizations t, NotifMode mode) => switch (mode) {
  NotifMode.notification => t.notifModeSound,
  NotifMode.silent => t.notifModeSilent,
  NotifMode.off => t.notifModeOff,
};
