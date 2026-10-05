import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../models/mosque.dart';

/// One pin on the mosque map: a single mosque, or a bubble standing for
/// [count] of them, placed at their average position.
class MosqueCluster {
  final double latitude;
  final double longitude;
  final int count;

  /// The mosque itself when [count] is 1.
  final Mosque? mosque;

  /// What the members span — where tapping a bubble zooms to.
  final GeoBox bounds;

  const MosqueCluster({
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.mosque,
    required this.bounds,
  });
}

/// One zoom level's pins as flat arrays: cheap to hand back from the
/// background isolate, and to scan on every frame without allocating.
class ClusterLevel {
  final Float64List latitude;
  final Float64List longitude;
  final Int32List count;

  /// Index into [MosqueClusters.mosques] for a single-mosque pin, -1 for a
  /// bubble.
  final Int32List mosque;

  /// South, west, north, east of each pin's members, four per pin.
  final Float64List bounds;

  const ClusterLevel({
    required this.latitude,
    required this.longitude,
    required this.count,
    required this.mosque,
    required this.bounds,
  });

  int get length => latitude.length;
}

/// The mosque map's pins at every zoom level, grouped by a pixel grid: all
/// mosques in the same [_cellPixels] square become one bubble, then bubbles
/// that still landed within [_mergePixels] of each other across a cell edge
/// are folded together.
///
/// Built in a background isolate, every level at once ([build]) — grouping
/// one level of 15,000 mosques takes ~10 ms, which done on the UI thread
/// while zooming dropped frames on a mid-range phone.
class MosqueClusters {
  final List<Mosque> mosques;
  final List<ClusterLevel> _levels;

  const MosqueClusters._(this.mosques, this._levels);

  static const empty = MosqueClusters._([], []);

  /// The furthest-out level worked out; anything further out uses it.
  static const minZoom = 2;

  /// From this zoom in, every mosque is its own pin.
  static const unclusteredFromZoom = 17;

  static const _cellPixels = 64.0;
  static const _mergePixels = 44.0;

  bool get isEmpty => mosques.isEmpty;

  static Future<MosqueClusters> build(List<Mosque> mosques) async {
    if (mosques.isEmpty) return empty;
    final n = mosques.length;
    final lat = Float64List(n);
    final lon = Float64List(n);
    for (var i = 0; i < n; i++) {
      lat[i] = mosques[i].latitude;
      lon[i] = mosques[i].longitude;
    }
    final levels = await Isolate.run(() => _computeLevels(lat, lon));
    return MosqueClusters._(List.unmodifiable(mosques), levels);
  }

  /// Same as [build], on the calling thread — for tests.
  static MosqueClusters buildSync(List<Mosque> mosques) {
    final lat = Float64List.fromList([for (final m in mosques) m.latitude]);
    final lon = Float64List.fromList([for (final m in mosques) m.longitude]);
    return MosqueClusters._(mosques, _computeLevels(lat, lon));
  }

  ClusterLevel? at(int zoom) => _levels.isEmpty
      ? null
      : _levels[zoom.clamp(minZoom, unclusteredFromZoom) - minZoom];

  MosqueCluster clusterAt(ClusterLevel level, int i) {
    final index = level.mosque[i];
    return MosqueCluster(
      latitude: level.latitude[i],
      longitude: level.longitude[i],
      count: level.count[i],
      mosque: index >= 0 ? mosques[index] : null,
      bounds: (
        south: level.bounds[i * 4],
        west: level.bounds[i * 4 + 1],
        north: level.bounds[i * 4 + 2],
        east: level.bounds[i * 4 + 3],
      ),
    );
  }
}

List<ClusterLevel> _computeLevels(Float64List lat, Float64List lon) {
  final n = lat.length;
  final x = Float64List(n);
  final y = Float64List(n);
  for (var i = 0; i < n; i++) {
    x[i] = (lon[i] + 180) / 360;
    final phi = lat[i].clamp(-85.0, 85.0) * math.pi / 180;
    y[i] = (1 - math.log(math.tan(phi) + 1 / math.cos(phi)) / math.pi) / 2;
  }
  return [
    for (
      var zoom = MosqueClusters.minZoom;
      zoom <= MosqueClusters.unclusteredFromZoom;
      zoom++
    )
      zoom == MosqueClusters.unclusteredFromZoom
          ? _singles(lat, lon)
          : _levelAt(zoom, lat, lon, x, y),
  ];
}

ClusterLevel _singles(Float64List lat, Float64List lon) {
  final n = lat.length;
  final bounds = Float64List(n * 4);
  for (var i = 0; i < n; i++) {
    bounds
      ..[i * 4] = lat[i]
      ..[i * 4 + 1] = lon[i]
      ..[i * 4 + 2] = lat[i]
      ..[i * 4 + 3] = lon[i];
  }
  return ClusterLevel(
    latitude: Float64List.fromList(lat),
    longitude: Float64List.fromList(lon),
    count: Int32List(n)..fillRange(0, n, 1),
    mosque: Int32List.fromList(List.generate(n, (i) => i)),
    bounds: bounds,
  );
}

ClusterLevel _levelAt(
  int zoom,
  Float64List lat,
  Float64List lon,
  Float64List x,
  Float64List y,
) {
  final worldPixels = 256.0 * math.pow(2, zoom);
  final cellsPerSide = worldPixels / MosqueClusters._cellPixels;
  final cells = <int, _Group>{};
  for (var i = 0; i < lat.length; i++) {
    final cx = (x[i] * cellsPerSide).floor();
    final cy = (y[i] * cellsPerSide).floor();
    (cells[_key(cx, cy)] ??= _Group(cx, cy, i)).add(lat[i], lon[i], x[i], y[i]);
  }

  // Biggest first, so a bubble swallows its stragglers rather than the
  // other way round.
  final groups = cells.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  for (final group in groups) {
    if (group.absorbed) continue;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final other = cells[_key(group.cx + dx, group.cy + dy)];
        if (other == null || other.absorbed) continue;
        final ddx = (group.meanX - other.meanX) * worldPixels;
        final ddy = (group.meanY - other.meanY) * worldPixels;
        if (ddx * ddx + ddy * ddy <
            MosqueClusters._mergePixels * MosqueClusters._mergePixels) {
          group.absorb(other);
        }
      }
    }
  }

  final kept = groups.where((g) => !g.absorbed).toList();
  final m = kept.length;
  final level = ClusterLevel(
    latitude: Float64List(m),
    longitude: Float64List(m),
    count: Int32List(m),
    mosque: Int32List(m),
    bounds: Float64List(m * 4),
  );
  for (var i = 0; i < m; i++) {
    final g = kept[i];
    level.latitude[i] = g.sumLat / g.count;
    level.longitude[i] = g.sumLon / g.count;
    level.count[i] = g.count;
    level.mosque[i] = g.count == 1 ? g.first : -1;
    level.bounds
      ..[i * 4] = g.south
      ..[i * 4 + 1] = g.west
      ..[i * 4 + 2] = g.north
      ..[i * 4 + 3] = g.east;
  }
  return level;
}

// Cell columns stay well under 2^30 even at the deepest clustered zoom.
int _key(int cx, int cy) => cx * 1073741824 + cy;

class _Group {
  final int cx;
  final int cy;
  final int first;
  int count = 0;
  bool absorbed = false;
  double sumX = 0, sumY = 0, sumLat = 0, sumLon = 0;
  double south = 90, west = 180, north = -90, east = -180;

  _Group(this.cx, this.cy, this.first);

  double get meanX => sumX / count;
  double get meanY => sumY / count;

  void add(double lat, double lon, double x, double y) {
    count++;
    sumX += x;
    sumY += y;
    sumLat += lat;
    sumLon += lon;
    south = math.min(south, lat);
    north = math.max(north, lat);
    west = math.min(west, lon);
    east = math.max(east, lon);
  }

  void absorb(_Group other) {
    other.absorbed = true;
    count += other.count;
    sumX += other.sumX;
    sumY += other.sumY;
    sumLat += other.sumLat;
    sumLon += other.sumLon;
    south = math.min(south, other.south);
    north = math.max(north, other.north);
    west = math.min(west, other.west);
    east = math.max(east, other.east);
  }
}
