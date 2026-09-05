import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place found via search or reverse-geocoding — enough to build a custom
/// [City] (see prayer_day.dart) once the user picks it.
class GeocodeResult {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const GeocodeResult({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

/// Free-text city search and GPS reverse-geocoding backed by OpenStreetMap's
/// Nominatim — a public, keyless "database of all cities" that lets the app
/// support any place in the world, not just a curated list.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Nominatim's usage policy requires a descriptive User-Agent identifying
  // the app rather than a generic HTTP client string.
  static const _userAgent = 'PrayerTimeApp (Flutter prayer times app)';

  Future<List<GeocodeResult>> search(
    String query, {
    String language = 'en',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'accept-language': language,
    });

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .whereType<GeocodeResult>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<GeocodeResult?> reverse(
    double latitude,
    double longitude, {
    String language = 'en',
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'jsonv2',
      'addressdetails': '1',
      'accept-language': language,
    });

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _fromJson(
        json,
        fallbackLatitude: latitude,
        fallbackLongitude: longitude,
      );
    } catch (_) {
      return null;
    }
  }

  GeocodeResult? _fromJson(
    Map<String, dynamic> json, {
    double? fallbackLatitude,
    double? fallbackLongitude,
  }) {
    final address = json['address'] as Map<String, dynamic>?;
    final city =
        address?['city'] ??
        address?['town'] ??
        address?['village'] ??
        address?['municipality'] ??
        address?['county'] ??
        json['name'];
    final country = address?['country'] as String?;
    final latitude =
        double.tryParse(json['lat']?.toString() ?? '') ?? fallbackLatitude;
    final longitude =
        double.tryParse(json['lon']?.toString() ?? '') ?? fallbackLongitude;

    if (city is! String || latitude == null || longitude == null) return null;

    return GeocodeResult(
      city: city,
      country: country ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
