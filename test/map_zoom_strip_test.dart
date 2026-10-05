import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:prayertime/l10n/app_localizations.dart';
import 'package:prayertime/widgets/map_zoom_strip.dart';

/// A bare map (no tiles, so nothing goes to the network) with the zoom strip
/// on the side [onLeft] says, moving it when the strip asks to.
class _Harness extends StatefulWidget {
  final MapController controller;
  final ValueNotifier<int> mapTouched;
  final List<bool> sideChanges;

  const _Harness({
    required this.controller,
    required this.mapTouched,
    required this.sideChanges,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool onLeft = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: widget.controller,
                options: const MapOptions(
                  initialCenter: LatLng(41.3, 69.2),
                  initialZoom: 13,
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: const [],
              ),
            ),
            Positioned(
              left: onLeft ? 0 : null,
              right: onLeft ? null : 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: MapZoomStrip(
                  controller: widget.controller,
                  minZoom: 3,
                  maxZoom: 19,
                  onLeft: onLeft,
                  onSideChanged: (left) {
                    widget.sideChanges.add(left);
                    setState(() => onLeft = left);
                  },
                  mapTouched: widget.mapTouched,
                  onInteractionStart: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late MapController controller;
  late ValueNotifier<int> mapTouched;
  late List<bool> sideChanges;

  // The default test screen is 800×600; the strip starts on the right edge,
  // its touch zone the 40 px against it.
  const onStrip = Offset(785, 300);

  Future<void> pumpStrip(WidgetTester tester) async {
    controller = MapController();
    mapTouched = ValueNotifier(0);
    sideChanges = [];
    await tester.pumpWidget(
      _Harness(
        controller: controller,
        mapTouched: mapTouched,
        sideChanges: sideChanges,
      ),
    );
    await tester.pump();
  }

  /// Holds for [time] with frames coming as on a phone — an animation
  /// counts from its first frame, so a single long pump would hold for no
  /// time at all.
  Future<void> hold(WidgetTester tester, Duration time) async {
    final end = time.inMilliseconds;
    for (var t = 0; t < end; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Lets every timer the strip may have started (the button's auto-hide)
  /// run out, so none is left pending when the test ends.
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  testWidgets('dragging along the strip zooms, and leaves it where it is', (
    tester,
  ) async {
    await pumpStrip(tester);
    final gesture = await tester.startGesture(onStrip);
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();

    expect(controller.camera.zoom, greaterThan(13));
    expect(sideChanges, isEmpty);
    expect(find.text('Перенести влево'), findsNothing);
    await drain(tester);
  });

  testWidgets('a long press brings up the button, which moves the strip', (
    tester,
  ) async {
    await pumpStrip(tester);
    final gesture = await tester.startGesture(onStrip);
    await hold(tester, const Duration(milliseconds: 300));
    expect(find.text('Перенести влево'), findsNothing);

    await hold(tester, const Duration(milliseconds: 500));
    expect(find.text('Перенести влево'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    // Let go without pulling: the button stays up to be tapped.
    expect(find.text('Перенести влево'), findsOneWidget);

    await tester.tap(find.text('Перенести влево'));
    await tester.pumpAndSettle();

    expect(sideChanges, [true]);
    expect(controller.camera.zoom, 13);
    await drain(tester);
  });

  testWidgets('held, then dragged across without letting go, it moves', (
    tester,
  ) async {
    await pumpStrip(tester);
    final gesture = await tester.startGesture(onStrip);
    await hold(tester, const Duration(milliseconds: 700));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(sideChanges, [true]);
    expect(controller.camera.zoom, 13);
    await drain(tester);
  });

  testWidgets('not pulled far enough, it settles back on its own side', (
    tester,
  ) async {
    await pumpStrip(tester);
    final gesture = await tester.startGesture(onStrip);
    await hold(tester, const Duration(milliseconds: 700));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(sideChanges, isEmpty);
    await drain(tester);
  });

  testWidgets('touching the map puts the button away', (tester) async {
    await pumpStrip(tester);
    final gesture = await tester.startGesture(onStrip);
    await hold(tester, const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Перенести влево'), findsOneWidget);

    mapTouched.value++;
    await tester.pumpAndSettle();

    expect(find.text('Перенести влево'), findsNothing);
    await drain(tester);
  });

  testWidgets('it can go back again from the left', (tester) async {
    await pumpStrip(tester);
    var gesture = await tester.startGesture(onStrip);
    await hold(tester, const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести влево'));
    await tester.pumpAndSettle();
    expect(sideChanges, [true]);

    gesture = await tester.startGesture(const Offset(15, 300));
    await hold(tester, const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перенести вправо'));
    await tester.pumpAndSettle();

    expect(sideChanges, [true, false]);
    await drain(tester);
  });
}
