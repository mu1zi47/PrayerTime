import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prayertime/widgets/app_switch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayertime/main.dart';
import 'package:prayertime/models/notif_mode.dart';
import 'package:prayertime/models/prayer_day.dart';
import 'package:prayertime/services/connectivity_service.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/services/prayer_times_api.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/widgets/notif_mode_selector.dart';
import 'package:prayertime/widgets/ambient_surface.dart';
import 'package:prayertime/widgets/settings_widgets.dart';

class _InstantFakeApi extends PrayerTimesApi {
  @override
  Future<PrayerFetchResult> fetchDaysWindow({
    required City city,
    required int methodCode,
    required int school,
    required DateTime centerDay,
    required int pastDays,
    required int futureDays,
    String? tune,
  }) async {
    return PrayerFetchResult(
      days: [
        for (var offset = -pastDays; offset <= futureDays; offset++)
          PrayerDay(
            date: centerDay.add(Duration(days: offset)),
            fajr: '05:00',
            sunrise: '06:30',
            zuhr: '12:30',
            asr: '15:30',
            maghrib: '18:30',
            isha: '20:00',
            tahajjud: '02:30',
          ),
      ],
      timeZone: city.timeZone,
    );
  }
}

class _AlwaysOnline extends ConnectivityService {
  const _AlwaysOnline();
  @override
  Future<bool> hasConnection() async => true;
}

/// A phone where the notification prompt was refused.
class _RefusedNotifications extends NoopNotificationService {
  @override
  Future<bool?> areNotificationsAllowed() async => false;
}

AppState _appState({
  InstallTimes? installTimes,
  NotificationService? notifications,
}) => AppState(
  api: _InstantFakeApi(),
  notifications: notifications ?? NoopNotificationService(),
  connectivity: const _AlwaysOnline(),
  installTimes: () async => installTimes,
);

Widget _app({InstallTimes? installTimes}) =>
    PrayerTimeApp(appState: _appState(installTimes: installTimes));

final _installed = DateTime.utc(2026, 9, 15, 21, 59, 29);

void main() {
  testWidgets('a fresh install lands in setup, not the app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Step one is the language picker — everything after it is read in
    // whatever language is chosen here. With nothing stored yet the app
    // follows the test environment's own locale, hence the English chrome
    // around a list that names each language in itself.
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Prayer'), findsNothing);
  });

  testWidgets('walking the steps through to the end opens the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Seven steps, with an optional persistent notification at the end.
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Prayer'), findsOneWidget);
  });

  testWidgets('refused notifications leave the modes off and locked, '
      'under a notice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appState = _appState(notifications: _RefusedNotifications());

    await tester.pumpWidget(PrayerTimeApp(appState: appState));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Allow notifications'), findsOneWidget);
    final prayersPanel = find.byKey(
      const ValueKey('setup-notification-prayers'),
    );
    expect(
      find.descendant(
        of: prayersPanel,
        matching: find.byType(NotifModeSelector),
      ),
      findsNWidgets(5),
    );

    final fajrSilent = find.descendant(
      of: find.byType(NotifModeSelector).first,
      matching: find.byIcon(Icons.volume_off_rounded),
    );
    await tester.ensureVisible(fajrSilent);
    await tester.pumpAndSettle();
    await tester.tap(fajrSilent);
    // The toast's overlay goes in on this frame, the toast itself on the
    // next — see AppToast.show.
    await tester.pump();
    await tester.pump();

    expect(find.text('Allow notifications first'), findsOneWidget);
    // The choice itself is kept for when notifications are allowed.
    expect(appState.notifMode['fajr'], NotifMode.notification);

    // Lets the toast run out rather than leaving its timer pending.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('language changes and grouped city actions fit a small screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final label in ['Русский', "O'zbekcha (lotin)", 'English']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Back'), findsOneWidget);
    final backPanel = find.ancestor(
      of: find.text('Back'),
      matching: find.byType(GlassPanel),
    );
    expect(
      tester.getCenter(find.text('Back')).dy,
      closeTo(tester.getCenter(backPanel).dy, .1),
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    final city = find.byKey(const ValueKey('setup-selected-city'));
    expect(city, findsOneWidget);
    expect(
      find.descendant(of: city, matching: find.text('Detect automatically')),
      findsNothing,
    );
    expect(
      find.descendant(of: city, matching: find.text('Choose manually')),
      findsNothing,
    );
    final detectPanel = find.ancestor(
      of: find.text('Detect automatically'),
      matching: find.byType(GlassPanel),
    );
    final manualPanel = find.ancestor(
      of: find.text('Choose manually'),
      matching: find.byType(GlassPanel),
    );
    expect(detectPanel, findsOneWidget);
    expect(manualPanel, findsOneWidget);
    expect(tester.element(detectPanel), same(tester.element(manualPanel)));
    expect(tester.takeException(), isNull);
  });

  for (final height in [640.0, 1000.0]) {
    testWidgets(
      'option panels wrap content within available height at ${height.toInt()}px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(390, height);
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();
        for (var step = 0; step < 5; step++) {
          if ([0, 1, 3, 4].contains(step)) {
            final panel = find
                .byKey(const ValueKey('setup-options-panel'))
                .hitTestable();
            expect(panel, findsOneWidget);
            final rows = find.descendant(
              of: panel,
              matching: find.byType(GroupRows),
            );
            final contentHeight = tester.getSize(rows).height;
            final panelHeight = tester.getSize(panel).height;
            expect(panelHeight, lessThanOrEqualTo(contentHeight + .1));
            if (height == 1000) expect(panelHeight, closeTo(contentHeight, .1));
            if (contentHeight > panelHeight) {
              final list = find.descendant(
                of: panel,
                matching: find.byType(ListView),
              );
              await tester.drag(list, const Offset(0, -150));
              await tester.pumpAndSettle();
              final scrollable = find.descendant(
                of: list,
                matching: find.byType(Scrollable),
              );
              expect(
                tester.state<ScrollableState>(scrollable).position.pixels,
                greaterThan(0),
              );
            }
          }
          expect(tester.takeException(), isNull);
          if (step < 4) {
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
          }
        }
      },
    );
  }

  testWidgets('step seven stays off until explicitly enabled', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var enabled = false;
    final writes = <bool>[];
    const channel = MethodChannel('uz.mu1zi47.prayertime/now_bar');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'setEnabled') {
        enabled = call.arguments as bool;
        writes.add(enabled);
        return null;
      }
      if (call.method == 'status') {
        return <String, Object?>{
          'enabled': enabled,
          'isNowBar': true,
          'notificationsAllowed': true,
          'promotionAllowed': true,
          'liveForAllApps': true,
        };
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Now Bar'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(writes, isEmpty);
    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(writes, [true]);
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Prayer'), findsOneWidget);
  });

  testWidgets('an install that predates setup is left alone', (tester) async {
    // No 'onboarding_done', but settings on disk: someone who has been
    // using the app since before this flow existed.
    SharedPreferences.setMockInitialValues({'locale': 'ru'});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
  });

  testWidgets('settings restored from a backup onto a new install go '
      'through setup again', (tester) async {
    // A finished setup from an older version, restored by Android's backup
    // onto an install that has never been updated.
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'locale': 'ru',
    });

    await tester.pumpWidget(
      _app(installTimes: (installed: _installed, updated: _installed)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Намаз'), findsNothing);
  });

  testWidgets('setup recorded on a different install runs again', (
    tester,
  ) async {
    final updated = _installed.add(const Duration(days: 3));
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'onboarding_install_time': _installed
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      'locale': 'ru',
    });

    await tester.pumpWidget(
      _app(installTimes: (installed: _installed, updated: updated)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsNothing);
  });

  testWidgets('setup done on this very install stays done', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'onboarding_install_time': _installed.millisecondsSinceEpoch,
      'locale': 'ru',
    });

    await tester.pumpWidget(
      _app(installTimes: (installed: _installed, updated: _installed)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
  });

  testWidgets('an in-place update from an older version keeps its setup', (
    tester,
  ) async {
    // Set up under a version that didn't record the install yet, then
    // updated in place — so the install has been updated since.
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'locale': 'ru',
    });

    await tester.pumpWidget(
      _app(
        installTimes: (
          installed: _installed,
          updated: _installed.add(const Duration(days: 40)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Намаз'), findsOneWidget);
  });
}
