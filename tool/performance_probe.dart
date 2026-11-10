// On-device comparative probe: flutter run --profile -t tool/performance_probe.dart
// Uses existing settings; navigation and scrolling never edit them.
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:prayertime/main.dart' as app;
import 'package:prayertime/navigation.dart';
import 'package:prayertime/state/app_state.dart';
import 'package:prayertime/screens/names_screen.dart';
import 'package:prayertime/screens/notification_sound_sheet.dart';
import 'package:prayertime/models/notif_sound.dart';

final _frames = <FrameTiming>[];
final _clock = Stopwatch()..start();
var _pointer = 200;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
  final state = AppState();
  runApp(app.PrayerTimeApp(appState: state));
  unawaited(_run(state));
}

Future<void> _wait([int milliseconds = 1100]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

bool _visible(Element element) {
  var visible = true;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Offstage && widget.offstage) visible = false;
    return visible;
  });
  return visible;
}

List<Element> _elements(bool Function(Element) predicate) {
  final found = <Element>[];
  void visit(Element element) {
    if (predicate(element) && _visible(element)) found.add(element);
    element.visitChildElements(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildElements(visit);
  return found;
}

Future<void> _tapIcon(IconData icon) async {
  final element = _elements(
    (e) => e.widget is Icon && (e.widget as Icon).icon == icon,
  ).last;
  final box = element.findRenderObject()! as RenderBox;
  final point = box.localToGlobal(box.size.center(Offset.zero));
  final pointer = ++_pointer;
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      pointer: pointer,
      position: point,
      timeStamp: _clock.elapsed,
    ),
  );
  await _wait(70);
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      pointer: pointer,
      position: point,
      timeStamp: _clock.elapsed,
    ),
  );
  await _wait();
}

ScrollableState _scrollable() => _elements(
  (e) =>
      e is StatefulElement &&
      e.state is ScrollableState &&
      (e.state as ScrollableState).position.axis == Axis.vertical &&
      (e.state as ScrollableState).position.hasContentDimensions &&
      (e.state as ScrollableState).position.maxScrollExtent > 100,
).map((e) => (e as StatefulElement).state as ScrollableState).last;

Future<void> _swipe(double distance, {int steps = 30}) async {
  final scroll = _scrollable();
  final box = scroll.context.findRenderObject()! as RenderBox;
  final local = Offset(
    box.size.width * .5,
    distance < 0 ? box.size.height * .75 : box.size.height * .25,
  );
  var point = box.localToGlobal(local);
  final pointer = ++_pointer;
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      pointer: pointer,
      position: point,
      timeStamp: _clock.elapsed,
    ),
  );
  for (var i = 0; i < steps; i++) {
    await _wait(16);
    final delta = Offset(0, distance / steps);
    point += delta;
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        pointer: pointer,
        position: point,
        delta: delta,
        timeStamp: _clock.elapsed,
      ),
    );
  }
  await _wait(100);
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      pointer: pointer,
      position: point,
      timeStamp: _clock.elapsed,
    ),
  );
  await _wait(400);
}

Future<void> _phase(String name, Future<void> Function() action) async {
  await _wait(500);
  _frames.clear();
  await action();
  await _wait(600); // Timing callbacks arrive in batches.
  final frames = List<FrameTiming>.of(_frames);
  double percentile(List<double> values, double fraction) {
    values.sort();
    return values.isEmpty
        ? 0
        : values[((values.length - 1) * fraction).round()];
  }

  final build = frames
      .map((t) => t.buildDuration.inMicroseconds / 1000)
      .toList();
  final raster = frames
      .map((t) => t.rasterDuration.inMicroseconds / 1000)
      .toList();
  final refresh =
      WidgetsBinding.instance.platformDispatcher.displays.first.refreshRate;
  final budget = 1000 / refresh;
  debugPrint(
    'PERF_PROBE ${jsonEncode({'phase': name, 'frames': frames.length, 'refresh_hz': refresh, 'build_p95_ms': percentile(build, .95), 'raster_p50_ms': percentile(raster, .5), 'raster_p95_ms': percentile(raster, .95), 'raster_max_ms': percentile(raster, 1), 'over_budget': frames.where((f) => f.buildDuration.inMicroseconds / 1000 > budget || f.rasterDuration.inMicroseconds / 1000 > budget).length})}',
  );
}

Future<void> _run(AppState state) async {
  try {
    for (var i = 0; i < 200 && (!state.isRestored || state.days.isEmpty); i++) {
      await _wait(100);
    }
    if (!state.onboardingDone || state.days.isEmpty) {
      throw StateError(
        'Existing setup and a loaded schedule are required; nothing is changed.',
      );
    }
    await _wait(1800);
    await _phase('tabs', () async {
      for (var i = 0; i < 3; i++) {
        await _tapIcon(Icons.grid_view_rounded);
        await _tapIcon(Icons.tune_rounded);
        await _tapIcon(Icons.home_rounded);
      }
    });
    final navigator = navigatorKey.currentState!;
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => NamesScreen(appState: state)),
      ),
    );
    await _wait(1600);
    navigator.pop(); // The accuracy notice, not the names screen.
    await _wait();
    await _phase('names_scroll', () async {
      for (var i = 0; i < 3; i++) {
        await _swipe(-280);
        await _swipe(240);
      }
    });
    navigator.pop();
    await _wait();
    for (var trial = 0; trial < 2; trial++) {
      await _phase('sounds_open_$trial', () async {
        unawaited(
          showSoundPicker(
            navigator.overlay!.context,
            title: 'Performance probe',
            current: const NotifSound.phoneDefault(),
          ),
        );
        await _wait(1800);
      });
      await _phase('sounds_scroll_$trial', () async {
        for (var i = 0; i < 3; i++) {
          await _swipe(-260);
          await _swipe(-260);
        }
      });
      navigator.pop();
      await _wait();
    }
    debugPrint('PERF_PROBE_DONE');
  } catch (error, trace) {
    debugPrint('PERF_PROBE_ERROR $error\n$trace');
  }
}
