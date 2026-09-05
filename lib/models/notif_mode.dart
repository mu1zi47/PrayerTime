import 'package:flutter/material.dart';

enum NotifMode {
  notification,
  silent;

  static NotifMode fromName(String? name) => NotifMode.values.firstWhere(
    (m) => m.name == name,
    orElse: () => NotifMode.notification,
  );
}

extension NotifModeStyle on NotifMode {
  IconData get icon => switch (this) {
    NotifMode.notification => Icons.notifications_rounded,
    NotifMode.silent => Icons.notifications_off_rounded,
  };

  String get label => switch (this) {
    NotifMode.notification => 'Уведомление',
    NotifMode.silent => 'Без звука',
  };
}
