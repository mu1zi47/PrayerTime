import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/mosque.dart';

/// A cell of the map grid (see MosqueMapScreen), by row and column.
typedef MosqueCell = (int row, int col);

/// What the device remembers of one cell: its mosques, and when they were
/// looked up.
typedef CachedCell = ({DateTime fetchedAt, List<Mosque> mosques});

/// Keeps every area the map has looked up on Overpass, one small file per
/// grid cell, so going back to a city shows its mosques at once — and
/// offline — instead of waiting on the network again.
class MosqueCache {
  MosqueCache({Future<Directory> Function()? directory})
    : _baseDirectory = directory ?? getApplicationCacheDirectory;

  final Future<Directory> Function() _baseDirectory;
  Future<Directory>? _dir;

  /// Bumped whenever the file format changes, so old files are simply not
  /// found rather than misread.
  static const _folder = 'mosques_v1';

  Future<Directory> get _directory => _dir ??= () async {
    final dir = Directory('${(await _baseDirectory()).path}/$_folder');
    await dir.create(recursive: true);
    return dir;
  }();

  File _file(Directory dir, MosqueCell cell) =>
      File('${dir.path}/${cell.$1}_${cell.$2}.tsv');

  /// Whatever is cached for each of [cells] — cells never looked up are
  /// simply absent.
  Future<Map<MosqueCell, CachedCell>> read(Iterable<MosqueCell> cells) async {
    final found = <MosqueCell, CachedCell>{};
    try {
      final dir = await _directory;
      await Future.wait(
        cells.map((cell) async {
          final file = _file(dir, cell);
          if (!await file.exists()) return;
          final lines = await file.readAsLines();
          final fetchedAt = int.tryParse(lines.firstOrNull ?? '');
          if (fetchedAt == null) return;
          found[cell] = (
            fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAt),
            mosques: lines
                .skip(1)
                .map(Mosque.fromTsv)
                .whereType<Mosque>()
                .toList(),
          );
        }),
      );
    } catch (_) {
      // A cache that can't be read is just an empty one.
    }
    return found;
  }

  /// Remembers [byCell] as just looked up — a cell with no mosques too, so
  /// an empty stretch of steppe isn't asked about again either.
  Future<void> write(Map<MosqueCell, List<Mosque>> byCell) async {
    try {
      final dir = await _directory;
      final now = DateTime.now().millisecondsSinceEpoch;
      await Future.wait(
        byCell.entries.map(
          (e) => _file(dir, e.key).writeAsString(
            ['$now', for (final m in e.value) m.toTsv()].join('\n'),
          ),
        ),
      );
    } catch (_) {
      // Out of space or similar — the map still works, it just asks again
      // next time.
    }
  }
}
