import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiveglow/l10n/app_localizations.dart';
import 'package:fiveglow/models/prayer_day.dart';
import 'package:fiveglow/models/prayer_log_status.dart';
import 'package:fiveglow/screens/prayer_calendar_screen.dart';
import 'package:fiveglow/services/notification_service.dart';
import 'package:fiveglow/state/app_state.dart';
import 'package:fiveglow/theme/app_design_system.dart';
import 'package:fiveglow/widgets/prayer_mark_indicator.dart';
import 'package:fiveglow/widgets/prayer_row_layout.dart';

class CalendarState extends AppState {
  CalendarState() : super(notifications: NoopNotificationService());
  DateTime now = DateTime.utc(2026, 11, 21, 20);
  @override
  DateTime get cityNow => now;
  @override
  PrayerDay get todayPrayerDay => PrayerDay(
    date: DateTime.utc(2026, 11, 21),
    fajr: '05:00',
    sunrise: '06:00',
    zuhr: '12:00',
    asr: '15:00',
    maghrib: '17:00',
    isha: '19:00',
    tahajjud: '02:00',
  );
}

void main() {
  testWidgets('future prayer writes are rejected until the exact start time', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = CalendarState()..now = DateTime.utc(2026, 11, 21, 18, 59);
    addTearDown(state.dispose);
    final date = state.cityNow;
    state.setPrayerStatus(date, 'isha', PrayerLogStatus.onTime);
    expect(state.prayerStatusFor(date, 'isha'), isNull);
    final tomorrow = date.add(const Duration(days: 1));
    state.setPrayerStatus(tomorrow, 'fajr', PrayerLogStatus.onTime);
    expect(state.prayerStatusFor(tomorrow, 'fajr'), isNull);
    state.now = DateTime.utc(2026, 11, 21, 19);
    state.setPrayerStatus(date, 'isha', PrayerLogStatus.onTime);
    expect(state.prayerStatusFor(date, 'isha'), PrayerLogStatus.onTime);
    await tester.pumpAndSettle();
  });

  testWidgets('calendar uses the same read button and binary legend', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final state = CalendarState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: PrayerCalendarScreen(appState: state),
      ),
    );
    await tester.pumpAndSettle();
    final rows = find.byType(PrayerRowLayout);
    for (final element in rows.evaluate()) {
      expect(
        tester.getSize(find.byWidget(element.widget)).height,
        AppSize.prayerRow,
      );
    }
    final button = find.byType(PrayerMarkIndicator).first;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      state.prayerStatusFor(state.cityNow, 'fajr'),
      PrayerLogStatus.onTime,
    );
    expect(
      tester.widget<PrayerMarkIndicator>(button).status,
      PrayerLogStatus.onTime,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(state.prayerStatusFor(state.cityNow, 'fajr'), isNull);
    expect(find.text('Прочитал с опозданием'), findsNothing);
    expect(find.text('Как прошёл Фаджр?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
