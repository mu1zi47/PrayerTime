/// A box on the map, in degrees.
typedef GeoBox = ({double south, double west, double north, double east});

/// A mosque as OpenStreetMap knows it — the map screen's one data type,
/// whether it came from the bundled region (see tool/update_mosques.dart),
/// the on-device cache or a live Overpass query.
///
/// Pure Dart on purpose: the update script builds the bundled asset with
/// this same class, outside of Flutter.
class Mosque {
  /// OSM element type initial plus its id ("n123", "w456", "r789") — unique
  /// across nodes, ways and relations, so overlapping sources merge instead
  /// of doubling up.
  final String id;
  final double latitude;
  final double longitude;

  final String? name;
  final String? nameRu;
  final String? nameEn;
  final String? nameUz;
  final String? nameUzCyrl;
  final String? address;

  const Mosque({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
    this.nameRu,
    this.nameEn,
    this.nameUz,
    this.nameUzCyrl,
    this.address,
  });

  /// The name in the app's language when OSM has one, otherwise whatever the
  /// mosque is locally called. [language] is one of "ru", "en", "uz" and
  /// "uz-Cyrl".
  String? localizedName(String language) {
    final localized = switch (language) {
      'ru' => nameRu,
      'en' => nameEn,
      'uz' => nameUz,
      'uz-Cyrl' => nameUzCyrl,
      _ => null,
    };
    return localized ?? name ?? nameRu ?? nameEn;
  }

  // The tags asked of Overpass, in the order its CSV output lists them after
  // type, id, lat and lon. CSV rather than JSON: JSON carries every tag of
  // every mosque, which made answers 5-6× bigger for the same pins.
  static const _csvTags = [
    'name',
    'name:ru',
    'name:en',
    'name:uz',
    'name:uz-Latn',
    'name:uz-Cyrl',
    'name:uz-cyr',
    'addr:full',
    'addr:street',
    'addr:housenumber',
    'addr:city',
  ];
  static final _csvColumns = 4 + _csvTags.length;

  /// An Overpass query for every mosque in [box] — buildings, sites and
  /// plain points alike (`out center` gives an outline its middle).
  static String overpassQuery(GeoBox box, {int timeoutSeconds = 20}) {
    final fields = [
      '::type',
      '::id',
      '::lat',
      '::lon',
      for (final tag in _csvTags) '"$tag"',
    ].join(',');
    return '[out:csv($fields;false;"\\t")][timeout:$timeoutSeconds];'
        'nwr["amenity"="place_of_worship"]["religion"="muslim"]'
        '(${box.south},${box.west},${box.north},${box.east});'
        'out center;';
  }

  /// Every mosque in an Overpass CSV answer from [overpassQuery], or null
  /// when it isn't one: an error page, or output cut short — a row that
  /// doesn't parse means the rest can't be trusted to be complete.
  static List<Mosque>? parseOverpassCsv(String body) {
    final rows = _splitCsv(body);
    if (rows == null) return null;
    final mosques = <Mosque>[];
    for (final f in rows) {
      if (f.length == 1 && f[0].trim().isEmpty) continue;
      if (f.length != _csvColumns) return null;
      final type = f[0];
      if (type != 'node' && type != 'way' && type != 'relation') return null;
      final lat = double.tryParse(f[2]);
      final lon = double.tryParse(f[3]);
      // An element whose center Overpass couldn't work out — skip it alone.
      if (lat == null || lon == null) continue;

      String? at(int i) {
        final v = f[i].replaceAll(RegExp(r'\s+'), ' ').trim();
        return v.isEmpty ? null : v;
      }

      final street = [at(12), at(13)].whereType<String>().join(', ');
      mosques.add(
        Mosque(
          id: '${type[0]}${f[1]}',
          latitude: lat,
          longitude: lon,
          name: at(4),
          nameRu: at(5),
          nameEn: at(6),
          nameUz: at(7) ?? at(8),
          nameUzCyrl: at(9) ?? at(10),
          address: at(11) ?? (street.isEmpty ? null : street) ?? at(14),
        ),
      );
    }
    return mosques;
  }

  /// Tab-separated rows the way Overpass writes them: a value holding a
  /// line break or a quote comes wrapped in quotes, with inner quotes
  /// doubled. Null for an unterminated quote — a cut-off answer.
  static List<List<String>>? _splitCsv(String body) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < body.length; i++) {
      final c = body[i];
      if (quoted) {
        if (c != '"') {
          field.write(c);
        } else if (i + 1 < body.length && body[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else if (c == '"' && field.isEmpty) {
        quoted = true;
      } else if (c == '\t') {
        row.add(field.toString());
        field.clear();
      } else if (c == '\n') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else if (c != '\r') {
        field.write(c);
      }
    }
    if (quoted) return null;
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  /// One tab-separated line — the bundled asset's and the on-device
  /// cache's format: compact, and quick to read back.
  String toTsv() {
    String clean(String? v) =>
        v == null ? '' : v.replaceAll(RegExp(r'[\t\r\n]+'), ' ');
    return [
      id,
      latitude.toStringAsFixed(6),
      longitude.toStringAsFixed(6),
      clean(name),
      clean(nameRu),
      clean(nameEn),
      clean(nameUz),
      clean(nameUzCyrl),
      clean(address),
    ].join('\t');
  }

  static Mosque? fromTsv(String line) {
    final f = line.split('\t');
    if (f.length != 9) return null;
    final lat = double.tryParse(f[1]);
    final lon = double.tryParse(f[2]);
    if (f[0].isEmpty || lat == null || lon == null) return null;
    String? at(int i) => f[i].isEmpty ? null : f[i];
    return Mosque(
      id: f[0],
      latitude: lat,
      longitude: lon,
      name: at(3),
      nameRu: at(4),
      nameEn: at(5),
      nameUz: at(6),
      nameUzCyrl: at(7),
      address: at(8),
    );
  }
}
