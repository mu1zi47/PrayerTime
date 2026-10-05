// Rebuilds assets/data/mosques_bundled.tsv — every mosque OpenStreetMap has
// in a box around Uzbekistan, border towns of its neighbours included
// (Shymkent, Osh, Khujand, Dushanbe, Dashoguz, ...). Bundled so the map opens
// instantly and works offline there; anywhere else the map screen asks
// Overpass (see MosqueService) and keeps the answer on the device.
//
//   dart run tool/update_mosques.dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:prayertime/models/mosque.dart';

/// Kept on whole half-degrees so it lines up with the map screen's cell
/// grid, which treats every cell inside it as already loaded.
const GeoBox _region = (south: 37.0, west: 55.5, north: 46.0, east: 73.5);

const _endpoints = [
  'https://lz4.overpass-api.de/api/interpreter',
  'https://z.overpass-api.de/api/interpreter',
  'https://overpass.openstreetmap.fr/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
];

Future<void> main() async {
  final mosques = (await _fetch())..sort((a, b) => a.id.compareTo(b.id));

  final updated = DateTime.now().toUtc().toIso8601String().substring(0, 10);
  final header = [
    '#',
    _region.south,
    _region.west,
    _region.north,
    _region.east,
    updated,
    '© OpenStreetMap contributors, ODbL',
  ].join('\t');

  final file = File('assets/data/mosques_bundled.tsv');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    [header, for (final m in mosques) m.toTsv()].join('\n'),
  );
  stdout.writeln(
    'Wrote ${mosques.length} mosques '
    '(${(await file.length()) ~/ 1024} KB) to ${file.path}',
  );
}

Future<List<Mosque>> _fetch() async {
  // Overpass answers 504/429 when it's busy rather than queueing, so a few
  // rounds with a pause in between ride that out.
  for (var round = 0; round < 3; round++) {
    if (round > 0) await Future<void>.delayed(const Duration(seconds: 20));
    for (final endpoint in _endpoints) {
      final mosques = await _fetchFrom(endpoint);
      if (mosques != null) return mosques;
    }
  }
  stderr.writeln('Every Overpass endpoint failed.');
  exit(1);
}

Future<List<Mosque>?> _fetchFrom(String endpoint) async {
  try {
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {'User-Agent': 'PrayerTimeApp (mosque data update)'},
          body: {
            'data': Mosque.overpassQuery(_region, timeoutSeconds: 170),
          },
        )
        .timeout(const Duration(minutes: 3));
    if (response.statusCode == 200) {
      final mosques = Mosque.parseOverpassCsv(utf8.decode(response.bodyBytes));
      if (mosques != null) return mosques;
      stderr.writeln('$endpoint: unparseable answer');
    } else {
      stderr.writeln('$endpoint: HTTP ${response.statusCode}');
    }
  } catch (e) {
    stderr.writeln('$endpoint: $e');
  }
  return null;
}
