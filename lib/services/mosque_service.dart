import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/mosque.dart';

/// The mosques shipped with the app, and the box they cover completely —
/// inside it there's nothing to look up.
typedef BundledMosques = ({GeoBox box, List<Mosque> mosques});

/// One area lookup in progress. [cancel] drops it: its requests are
/// aborted and [result] completes with null.
class MosqueFetch {
  final Future<List<Mosque>?> result;
  final void Function() cancel;

  const MosqueFetch(this.result, this.cancel);
}

/// Where the mosque map gets its pins: the bundled region (built by
/// tool/update_mosques.dart) and OpenStreetMap's Overpass API for anywhere
/// else — a public, keyless database of every mosque people have mapped.
class MosqueService {
  MosqueService({http.Client Function()? clientFactory})
    : _newClient = clientFactory ?? http.Client.new;

  /// One client per request, so a request that lost the race can be
  /// aborted by closing its client.
  final http.Client Function() _newClient;

  static const _bundledAsset = 'assets/data/mosques_bundled.tsv';

  // The public Overpass instances are often overloaded: the same query
  // takes 2 s on one and 50 s (or a 429/504) on another, and which one is
  // which changes by the minute. So rather than trying them in turn, a
  // lookup starts on one and brings in the next whenever the current ones
  // fail or haven't answered within [_hedgeAfter]; the first good answer
  // wins and the rest are aborted.
  static const _endpoints = [
    'https://lz4.overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];
  static const _hedgeAfter = Duration(seconds: 3);
  static const _requestTimeout = Duration(seconds: 25);
  static const _overallTimeout = Duration(seconds: 30);

  // Overpass's usage policy asks for an identifying User-Agent, same as
  // Nominatim's (see GeocodingService).
  static const _userAgent = 'PrayerTimeApp (Flutter prayer times app)';

  /// Alternates which of the two main servers goes first, so lookups
  /// spread over both instead of all queueing on one.
  static int _rotation = 0;

  /// Read once per app run and kept: the asset never changes while the
  /// app is running, and reopening the map shouldn't parse it again.
  static Future<BundledMosques>? _bundled;

  Future<BundledMosques> loadBundled() {
    final cached = _bundled;
    if (cached != null) return cached;
    final loading = _readBundled();
    _bundled = loading;
    // A failed read isn't kept, so the next screen open tries again.
    loading.then((_) {}, onError: (Object _) => _bundled = null);
    return loading;
  }

  Future<BundledMosques> _readBundled() async {
    final raw = await rootBundle.loadString(_bundledAsset);
    // Parsed off the UI isolate so the screen's opening animation doesn't
    // stutter on it.
    return compute(_parseBundled, raw);
  }

  /// Every mosque inside [box], or null when no server could answer.
  MosqueFetch fetchArea(GeoBox box) {
    final done = Completer<List<Mosque>?>();
    final clients = <http.Client>[];
    final query = Mosque.overpassQuery(box);
    final first = _rotation++ % 2;
    var started = 0;
    var failed = 0;
    Timer? hedge;
    Timer? overall;

    void finish(List<Mosque>? mosques) {
      if (done.isCompleted) return;
      done.complete(mosques);
      hedge?.cancel();
      overall?.cancel();
      for (final c in clients) {
        c.close();
      }
    }

    void startNext() {
      if (done.isCompleted || started == _endpoints.length) return;
      final endpoint = _endpoints[(first + started) % _endpoints.length];
      started++;
      final client = _newClient();
      clients.add(client);
      hedge?.cancel();
      hedge = Timer(_hedgeAfter, startNext);

      _query(client, endpoint, query).then((mosques) {
        if (mosques != null) return finish(mosques);
        if (++failed == _endpoints.length) return finish(null);
        startNext();
      });
    }

    overall = Timer(_overallTimeout, () => finish(null));
    startNext();
    return MosqueFetch(done.future, () => finish(null));
  }

  Future<List<Mosque>?> _query(
    http.Client client,
    String endpoint,
    String query,
  ) async {
    try {
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {'User-Agent': _userAgent},
            body: {'data': query},
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes);
      // Isolates cost a few ms to start — only worth it for a big answer.
      return body.length < 64 * 1024
          ? Mosque.parseOverpassCsv(body)
          : await compute(Mosque.parseOverpassCsv, body);
    } catch (_) {
      // Timeout, no network, or aborted because another server won.
      return null;
    }
  }
}

BundledMosques _parseBundled(String raw) {
  final lines = const LineSplitter().convert(raw);
  final header = lines.first.split('\t');
  return (
    box: (
      south: double.parse(header[1]),
      west: double.parse(header[2]),
      north: double.parse(header[3]),
      east: double.parse(header[4]),
    ),
    mosques: lines.skip(1).map(Mosque.fromTsv).whereType<Mosque>().toList(),
  );
}
