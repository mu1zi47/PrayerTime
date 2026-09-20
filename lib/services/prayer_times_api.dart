import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prayer_day.dart';

enum PrayerApiError {
  timeout,
  noConnection,
  serviceUnavailable,
  parseFailed,
  fetchFailed,
}

class PrayerApiException implements Exception {
  final PrayerApiError error;

  const PrayerApiException(this.error);

  @override
  String toString() => error.name;
}

/// A fetched batch of upcoming days plus the IANA time zone the API resolved
/// for the requested coordinates (e.g. "Asia/Tashkent") — needed so
/// [AppState] can compute the city's local time/UTC offset for a
/// just-picked custom city, whose time zone isn't known up front.
class PrayerFetchResult {
  final List<PrayerDay> days;
  final String timeZone;

  const PrayerFetchResult({required this.days, required this.timeZone});
}

class PrayerTimesApi {
  PrayerTimesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches a window of days centered on [centerDay] — [pastDays] before it
  /// through [futureDays] after it, inclusive. Used to keep enough of
  /// yesterday around that the current-prayer calculation can still say
  /// "Isha" between midnight and today's Fajr (see [AppState.loadPrayerTimes]
  /// and `computeCurrentPrayer`'s `todayIndex` fallback), and to give offline
  /// mode a real history/preview range rather than just "today onward".
  Future<PrayerFetchResult> fetchDaysWindow({
    required City city,
    required int methodCode,
    required int school,
    required DateTime centerDay,
    required int pastDays,
    required int futureDays,
    String? tune,
  }) async {
    final start = centerDay.subtract(Duration(days: pastDays));
    final end = centerDay.add(Duration(days: futureDays));

    var year = start.year;
    var month = start.month;
    var timeZone = '';
    final collected = <PrayerDay>[];

    Future<void> fetchAndTrackTimeZone(int y, int m) async {
      final result = await fetchMonth(
        city: city,
        methodCode: methodCode,
        school: school,
        tune: tune,
        year: y,
        month: m,
      );
      if (timeZone.isEmpty && result.timeZone.isNotEmpty) {
        timeZone = result.timeZone;
      }
      collected.addAll(result.days);
    }

    await fetchAndTrackTimeZone(year, month);
    while (collected.isEmpty || collected.last.date.isBefore(end)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      await fetchAndTrackTimeZone(year, month);
    }

    final windowDays =
        collected
            .where((d) => !d.date.isBefore(start) && !d.date.isAfter(end))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return PrayerFetchResult(days: windowDays, timeZone: timeZone);
  }

  /// Fetches one whole calendar month of days — used by the monthly
  /// prayer-times screen, which reaches a month either side of today and so
  /// beyond the window [fetchDaysWindow] keeps around.
  Future<PrayerFetchResult> fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required String? tune,
    required int year,
    required int month,
  }) async {
    final uri = Uri.https('api.aladhan.com', '/v1/calendar/$year/$month', {
      'latitude': '${city.latitude}',
      'longitude': '${city.longitude}',
      'method': '$methodCode',
      'school': '$school',
      'tune': ?tune,
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const PrayerApiException(PrayerApiError.timeout);
    } on SocketException {
      throw const PrayerApiException(PrayerApiError.noConnection);
    }

    if (response.statusCode != 200) {
      throw const PrayerApiException(PrayerApiError.serviceUnavailable);
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const PrayerApiException(PrayerApiError.parseFailed);
    }

    if (body['code'] != 200) {
      throw const PrayerApiException(PrayerApiError.fetchFailed);
    }

    final data = body['data'] as List;
    final days = data
        .map((e) => PrayerDay.fromApi(e as Map<String, dynamic>))
        .toList();

    var timeZone = '';
    if (data.isNotEmpty) {
      final meta = (data.first as Map<String, dynamic>)['meta'];
      if (meta is Map<String, dynamic>) {
        timeZone = meta['timezone'] as String? ?? '';
      }
    }

    return PrayerFetchResult(days: days, timeZone: timeZone);
  }
}
