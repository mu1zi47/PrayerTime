import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/screens/end_reminders_sheet.dart';
import 'package:prayertime/screens/now_bar_sheet.dart';
import 'package:prayertime/services/now_bar_bridge.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/state/app_state.dart';

void main() {
  testWidgets('grouped reminder sheet and picker fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(notifications: NoopNotificationService());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showEndRemindersSheet(context, state),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final add = find.text('Добавить напоминание');
    expect(add, findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Готово'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('expanded Now Bar instructions fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(notifications: NoopNotificationService());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showNowBarSheet(
                context,
                state,
                const NowBarStatus(
                  enabled: true,
                  showSchedule: true,
                  isNowBar: true,
                  notificationsAllowed: true,
                  promotionAllowed: false,
                  liveForAllApps: false,
                  developerOptionsEnabled: false,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsOneWidget);
    final info = find.byIcon(Icons.info_outline_rounded).first;
    await tester.tap(info);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final copy = lookupAppLocalizations(const Locale('ru')).nowBarDescription;
    expect(find.text(copy), findsOneWidget);
    expect(
      tester
          .widgetList<FadeTransition>(
            find.ancestor(
              of: find.text(copy),
              matching: find.byType(FadeTransition),
            ),
          )
          .any((w) => w.opacity.value > 0 && w.opacity.value < 1),
      isTrue,
    );
    await tester.pumpAndSettle();
    await tester.tap(info);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text(copy), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(copy), findsNothing);
    await tester.tap(info);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
