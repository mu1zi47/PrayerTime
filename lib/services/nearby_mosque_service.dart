import 'package:latlong2/latlong.dart';

import '../data/nearest_mosque.dart';
import '../models/mosque.dart';
import 'mosque_cache.dart';
import 'mosque_service.dart';

/// Shares the full map's bundled data, cell cache and Overpass client.
class NearbyMosqueService {
  NearbyMosqueService({MosqueService? mosques, MosqueCache? cache})
    : _mosques = mosques ?? MosqueService(),
      _cache = cache ?? MosqueCache();

  final MosqueService _mosques;
  final MosqueCache _cache;
  final List<MosqueFetch> _requests = [];
  int _generation = 0;

  Future<NearbyMosque?> find(LatLng position) async {
    final generation = ++_generation;
    final bundled = await _mosques.loadBundled();
    if (generation != _generation) return null;
    final bounds = bundled.box;
    if (position.latitude >= bounds.south &&
        position.latitude <= bounds.north &&
        position.longitude >= bounds.west &&
        position.longitude <= bounds.east) {
      return nearestMosque(bundled.mosques, position);
    }

    // Same complete 0.1-degree cells the full map stores. Wrapping columns
    // keeps requests local when the position is near the date line.
    final row = (position.latitude / .1).floor().clamp(-900, 899);
    final col = (position.longitude / .1).floor();
    final cells = <MosqueCell>{
      for (var dr = -1; dr <= 1; dr++)
        for (var dc = -1; dc <= 1; dc++)
          ((row + dr).clamp(-900, 899), (col + dc + 1800) % 3600 - 1800),
    };
    final cached = await _cache.read(cells);
    if (generation != _generation) return null;
    final fresh =
        cached.length == cells.length &&
        cached.values.every(
          (cell) => DateTime.now().difference(cell.fetchedAt).inDays < 7,
        );
    if (fresh) {
      return nearestMosque(
        cached.values.expand((cell) => cell.mosques),
        position,
      );
    }

    final fetched = <String, Mosque>{};
    var failed = false;
    // One request per longitude segment, including across the date line.
    final columns = cells.map((cell) => cell.$2).toSet().toList()..sort();
    final segments = <List<int>>[];
    for (final column in columns) {
      if (segments.isEmpty || column != segments.last.last + 1) {
        segments.add([column]);
      } else {
        segments.last.add(column);
      }
    }
    final minRow = cells.map((cell) => cell.$1).reduce((a, b) => a < b ? a : b);
    final maxRow = cells.map((cell) => cell.$1).reduce((a, b) => a > b ? a : b);
    for (final segment in segments) {
      final request = _mosques.fetchArea((
        south: minRow * .1,
        north: (maxRow + 1) * .1,
        west: segment.first * .1,
        east: (segment.last + 1) * .1,
      ));
      _requests.add(request);
      final result = await request.result;
      _requests.remove(request);
      if (generation != _generation) return null;
      if (result == null) {
        failed = true;
      } else {
        for (final mosque in result) {
          fetched[mosque.id] = mosque;
        }
      }
    }
    if (failed) {
      final fallback = nearestMosque(
        cached.values.expand((cell) => cell.mosques),
        position,
      );
      if (fallback != null) return fallback;
      throw StateError('Nearby mosques could not be loaded');
    }
    final byCell = <MosqueCell, List<Mosque>>{
      for (final cell in cells) cell: [],
    };
    for (final mosque in fetched.values) {
      byCell[((mosque.latitude / .1).floor(), (mosque.longitude / .1).floor())]
          ?.add(mosque);
    }
    await _cache.write(byCell);
    return nearestMosque(fetched.values, position);
  }

  void cancel() {
    _generation++;
    for (final request in _requests.toList()) {
      request.cancel();
    }
    _requests.clear();
  }
}
