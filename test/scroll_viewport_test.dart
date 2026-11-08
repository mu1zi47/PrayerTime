import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/screens/names_screen.dart';
import 'package:prayertime/screens/city_screen.dart';
import 'package:prayertime/screens/notification_sound_sheet.dart';
import 'package:prayertime/models/notif_sound.dart';
import 'package:prayertime/services/notification_service.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/widgets/ambient_surface.dart';

Widget app(Widget home) => MaterialApp(
  scrollBehavior: const StableScrollBehavior(),
  locale: const Locale('ru'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  testWidgets('a short glass list stays still when pulled past either edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GlassPanel(
                child: ListView(
                  children: const [PanelRow(child: Text('Only row'))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final bounds = tester.getRect(find.text('Only row'));
    for (final delta in [const Offset(0, 150), const Offset(0, -150)]) {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(delta);
      await tester.pump();
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      expect(tester.getRect(find.text('Only row')), bounds);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Only row')), bounds);
    }
  });

  for (final names in [true, false]) {
    testWidgets(
      '${names ? "names" : "cities"} keeps search below its rounded scrolling viewport',
      (tester) async {
        tester.view.physicalSize = const Size(360, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = AppState(notifications: NoopNotificationService());
        await tester.pumpWidget(
          app(
            names ? NamesScreen(appState: state) : CityScreen(appState: state),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (names) {
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }
        final list = find.byType(ListView).first;
        final panel = find
            .ancestor(of: list, matching: find.byType(GlassPanel))
            .first;
        final bounds = tester.getRect(panel);
        final search = tester.getRect(find.byType(TextField));
        expect(bounds.bottom, lessThan(search.top));
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.getRect(panel), bounds);
        expect(tester.getRect(find.byType(TextField)), search);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      },
    );
  }

  testWidgets('sound categories have separate panels and Done stays fixed', (
    tester,
  ) async {
    const channel = MethodChannel('uz.mu1zi47.prayertime/sounds');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'list') {
        return [
          for (final kind in ['notification', 'ringtone'])
            for (var i = 0; i < 20; i++)
              {'title': '$kind $i', 'uri': 'sound:$kind:$i', 'kind': kind},
        ];
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSoundPicker(
                context,
                title: 'Sounds',
                current: const NotifSound.phoneDefault(),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Готово'));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Готово')), before);
    expect(find.byType(GlassPanel), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
