import 'package:flutter/material.dart';

enum NotifMode {
  azan,
  notification,
  silent;

  static NotifMode fromName(String? name) =>
      NotifMode.values.firstWhere((m) => m.name == name, orElse: () => NotifMode.azan);
}

extension NotifModeStyle on NotifMode {
  IconData get icon => switch (this) {
        NotifMode.azan => Icons.campaign_rounded,
        NotifMode.notification => Icons.notifications_rounded,
        NotifMode.silent => Icons.notifications_off_rounded,
      };

  String get label => switch (this) {
        NotifMode.azan => 'Азан',
        NotifMode.notification => 'Уведомление',
        NotifMode.silent => 'Без звука',
      };
}
