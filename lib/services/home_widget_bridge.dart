import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/prayer_day.dart';
import '../widgets/prayer_icon.dart';
import 'prayer_log_store.dart';

/// Where the home-screen widget looks for its schedule. Public for the same
/// reason [kPrayerLogPrefsKey] is: the Android side reads this key straight
/// out of shared_preferences (see PrayerWidgetStore.kt), with no Flutter
/// engine running.
const kWidgetPayloadPrefsKey = 'widget_payload';

/// Feeds the Android home-screen widgets (all three of them) and the
/// current-prayer notification.
///
/// A widget can't call into Dart — it's drawn by the launcher, usually
/// with this app's process long dead — so everything it needs is written out
/// in one self-contained blob: the schedule, the city's UTC offset (so the
/// widget keeps the *selected city's* clock, like the app), and every string
/// already translated into the language chosen **in the app**, since the
/// widget has no access to that choice otherwise.
class HomeWidgetBridge {
  const HomeWidgetBridge();

  static const _channel = MethodChannel('uz.mu1zi47.prayertime/widget');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> publish({
    required List<PrayerDay> days,
    required Duration utcOffset,
    required ThemeMode themeMode,
    required AppLocalizations t,
  }) async {
    if (!_supported || days.isEmpty) return;

    final payload = {
      'version': 1,
      'offsetMinutes': utcOffset.inMinutes,
      // The widget paints itself in the theme chosen *here* rather than the
      // phone's, since the app's own setting can disagree with it. 'system'
      // hands that decision back to the phone.
      'theme': themeMode.name,
      'labels': {
        'next': t.nextPrayerLabel,
        'markDone': t.notifMarkDoneAction,
        'marked': t.widgetMarkedLabel,
        'noData': t.widgetNoDataLabel,
        // The current-prayer notification / Now Bar reads this same payload
        // (see PrayerStatusNotifier.kt).
        'open': t.nowBarOpenAction,
        'endsIn': t.nowBarEndsIn,
        'startsIn': t.nowBarStartsIn,
        'nowBarChannel': t.nowBarChannelName,
      },
      'names': {
        'fajr': nameForPrayer(t, PrayerKind.fajr),
        'sunrise': nameForPrayer(t, PrayerKind.sunrise),
        'zuhr': nameForPrayer(t, PrayerKind.zuhr),
        'asr': nameForPrayer(t, PrayerKind.asr),
        'maghrib': nameForPrayer(t, PrayerKind.maghrib),
        'isha': nameForPrayer(t, PrayerKind.isha),
      },
      'days': [
        for (final d in days)
          {
            'date': PrayerLogStore.dateKey(d.date),
            'times': {
              'fajr': d.fajr,
              // Not a prayer, but it's what closes Fajr's window — the widget
              // needs it to stop calling Fajr "happening now" all morning.
              'sunrise': d.sunrise,
              'zuhr': d.zuhr,
              'asr': d.asr,
              'maghrib': d.maghrib,
              'isha': d.isha,
            },
          },
      ],
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kWidgetPayloadPrefsKey, jsonEncode(payload));
    await refresh();
  }

  /// Nudges any placed widget to redraw — for when what changed is the log
  /// rather than the schedule, and the payload itself is still current.
  Future<void> refresh() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('refreshWidget');
    } catch (_) {
      // Ignored: nothing here is worth failing a user action over, and the
      // widget refreshes on its own schedule regardless.
    }
  }
}
