import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prayertime/data/mosque_clusters.dart';
import 'package:prayertime/models/mosque.dart';
import 'package:prayertime/services/mosque_cache.dart';
import 'package:prayertime/services/mosque_service.dart';

/// One Overpass CSV row: type, id, lat, lon, then the 11 tags in the order
/// Mosque.overpassQuery asks for them.
String _row(
  String type,
  int id,
  String lat,
  String lon, {
  String name = '',
  String ru = '',
  String street = '',
  String house = '',
}) => [
  type,
  id,
  lat,
  lon,
  name,
  ru,
  '',
  '',
  '',
  '',
  '',
  '',
  street,
  house,
  '',
].join('\t');

void main() {
  group('Mosque.parseOverpassCsv', () {
    test('reads nodes and outlines alike', () {
      final mosques = Mosque.parseOverpassCsv(
        [
          _row('node', 1, '41.3', '69.2', name: 'Minor', ru: 'Минор'),
          _row('way', 2, '41.31', '69.25', street: 'Navoiy', house: '12'),
        ].join('\n'),
      )!;

      expect(mosques.map((m) => m.id), ['n1', 'w2']);
      expect(mosques.first.nameRu, 'Минор');
      expect(mosques.last.latitude, 41.31);
      expect(mosques.last.address, 'Navoiy, 12');
    });

    test('keeps a quoted name with a line break in it as one row', () {
      final mosques = Mosque.parseOverpassCsv(
        _row('node', 3, '37.08', '57.46', name: '"Nazargah\nshrine"'),
      )!;

      expect(mosques.single.name, 'Nazargah shrine');
    });

    test('skips an element without a center but keeps the rest', () {
      final mosques = Mosque.parseOverpassCsv(
        [_row('relation', 4, '', ''), _row('node', 5, '1', '2')].join('\n'),
      )!;

      expect(mosques.single.id, 'n5');
    });

    test('rejects an error page or a cut-off answer', () {
      expect(Mosque.parseOverpassCsv('<html><body>504</body></html>'), isNull);
      expect(
        Mosque.parseOverpassCsv('${_row('node', 6, '1', '2')}\nnode\t7\t1.5'),
        isNull,
      );
      expect(
        Mosque.parseOverpassCsv(_row('node', 8, '1', '2', name: '"unclosed')),
        isNull,
      );
    });
  });

  test('the TSV form round-trips and flattens tabs and line breaks', () {
    const m = Mosque(
      id: 'w2',
      latitude: 41.311081,
      longitude: 69.240562,
      name: 'Minor\tmasjidi',
      nameUzCyrl: 'Минор',
      address: 'Tashkent\nOlmazor',
    );
    final back = Mosque.fromTsv(m.toTsv())!;

    expect(back.id, 'w2');
    expect(back.latitude, closeTo(41.311081, 1e-6));
    expect(back.name, 'Minor masjidi');
    expect(back.nameUzCyrl, 'Минор');
    expect(back.nameRu, isNull);
    expect(back.address, 'Tashkent Olmazor');
  });

  test('localizedName falls back to the local name', () {
    const m = Mosque(
      id: 'n1',
      latitude: 0,
      longitude: 0,
      name: 'Hazrati Imom',
      nameRu: 'Хазрати Имам',
    );

    expect(m.localizedName('ru'), 'Хазрати Имам');
    expect(m.localizedName('en'), 'Hazrati Imom');
    expect(m.localizedName('uz-Cyrl'), 'Hazrati Imom');
  });

  group('MosqueService.fetchArea', () {
    const box = (south: 41.0, west: 28.8, north: 41.1, east: 28.9);
    final answer = _row('node', 7, '41.05', '28.85');

    test('moves straight on when a server is busy', () async {
      final hosts = <String>[];
      final service = MosqueService(
        clientFactory: () => MockClient((request) async {
          hosts.add(request.url.host);
          return hosts.length == 1
              ? http.Response('busy', 429)
              : http.Response(answer, 200);
        }),
      );

      final found = await service.fetchArea(box).result;

      expect(hosts, hasLength(2));
      expect(found?.single.id, 'n7');
    });

    testWidgets('brings in another server when the first is slow', (
      tester,
    ) async {
      final hosts = <String>[];
      final never = Completer<http.Response>();
      final service = MosqueService(
        clientFactory: () => MockClient((request) {
          hosts.add(request.url.host);
          return hosts.length == 1
              ? never.future
              : Future.value(http.Response(answer, 200));
        }),
      );

      List<Mosque>? found;
      service.fetchArea(box).result.then((m) => found = m);
      await tester.pump(const Duration(seconds: 1));
      expect(hosts, hasLength(1));
      expect(found, isNull);

      await tester.pump(const Duration(seconds: 3));
      expect(hosts, hasLength(2));
      expect(found?.single.id, 'n7');

      // A real client aborts the loser when it's closed; MockClient can't,
      // so its request timeout is still ticking — let it run out.
      await tester.pump(const Duration(seconds: 30));
    });

    test('gives null once every server has failed', () async {
      var calls = 0;
      final service = MosqueService(
        clientFactory: () => MockClient((_) async {
          calls++;
          return http.Response('<html>504</html>', 504);
        }),
      );

      expect(await service.fetchArea(box).result, isNull);
      expect(calls, 4);
    });

    test('a cancelled lookup completes with null', () async {
      final service = MosqueService(
        clientFactory: () =>
            MockClient((_) => Completer<http.Response>().future),
      );

      final fetch = service.fetchArea(box);
      fetch.cancel();

      expect(await fetch.result, isNull);
    });
  });

  group('MosqueClusters', () {
    // Two mosques ~300 m apart in Tashkent, one in Samarkand.
    const a = Mosque(id: 'n1', latitude: 41.3000, longitude: 69.2400);
    const b = Mosque(id: 'n2', latitude: 41.3020, longitude: 69.2430);
    const c = Mosque(id: 'n3', latitude: 39.6540, longitude: 66.9750);
    final clusters = MosqueClusters.buildSync([a, b, c]);

    List<MosqueCluster> at(MosqueClusters clusters, int zoom) {
      final level = clusters.at(zoom)!;
      return [
        for (var i = 0; i < level.length; i++) clusters.clusterAt(level, i),
      ];
    }

    test('zoomed out, the two Tashkent ones share a bubble', () {
      final pins = at(clusters, 8);

      expect(pins, hasLength(2));
      final tashkent = pins.firstWhere((p) => p.count == 2);
      expect(tashkent.mosque, isNull);
      expect(tashkent.latitude, closeTo(41.301, 1e-6));
      expect(tashkent.bounds.north, b.latitude);
      expect(pins.firstWhere((p) => p.count == 1).mosque, c);
    });

    test('at street level every mosque is its own pin', () {
      final pins = at(clusters, MosqueClusters.unclusteredFromZoom);

      expect(pins.map((p) => p.mosque), [a, b, c]);
      // Zooms past the deepest level use it too.
      expect(at(clusters, 19).map((p) => p.mosque), [a, b, c]);
    });

    test('neighbours across a grid line still merge', () {
      // Straddling the 0° meridian, which is a cell edge at every zoom.
      final edge = MosqueClusters.buildSync([
        const Mosque(id: 'n4', latitude: 10, longitude: -0.0001),
        const Mosque(id: 'n5', latitude: 10, longitude: 0.0001),
      ]);

      expect(at(edge, 10).single.count, 2);
    });

    test('built in the background, it matches the inline build', () async {
      final background = await MosqueClusters.build([a, b, c]);

      for (final zoom in [4, 8, 12, 17]) {
        expect(
          at(background, zoom).map((p) => (p.latitude, p.count)),
          at(clusters, zoom).map((p) => (p.latitude, p.count)),
        );
      }
    });
  });

  test('MosqueCache keeps what it was given, empty cells included', () async {
    final dir = await Directory.systemTemp.createTemp('mosque_cache_test');
    addTearDown(() => dir.delete(recursive: true));
    final cache = MosqueCache(directory: () async => dir);
    const m = Mosque(id: 'n9', latitude: 41.05, longitude: 28.95, name: 'X');

    await cache.write({
      (410, 289): [m],
      (410, 290): [],
    });
    final read = await cache.read([(410, 289), (410, 290), (411, 289)]);

    expect(read.keys, unorderedEquals([(410, 289), (410, 290)]));
    expect(read[(410, 289)]!.mosques.single.name, 'X');
    expect(read[(410, 290)]!.mosques, isEmpty);
    expect(
      DateTime.now().difference(read[(410, 289)]!.fetchedAt),
      lessThan(const Duration(minutes: 1)),
    );
  });
}
