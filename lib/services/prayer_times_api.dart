import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prayer_day.dart';

enum PrayerApiError { timeout, noConnection, serviceUnavailable, parseFailed, fetchFailed }

class PrayerApiException implements Exception {
  final PrayerApiError error;

  const PrayerApiException(this.error);

  @override
  String toString() => error.name;
}

class PrayerTimesApi {
  PrayerTimesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PrayerDay>> fetchUpcomingDays({
    required City city,
    required int methodCode,
    required int school,
    required DateTime from,
    String? tune,
    int count = 10,
  }) async {
    var year = from.year;
    var month = from.month;

    var days =
        (await _fetchMonth(city: city, methodCode: methodCode, school: school, tune: tune, year: year, month: month))
            .where((d) => !d.date.isBefore(from))
            .toList();

    while (days.length < count) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      days.addAll(
        await _fetchMonth(city: city, methodCode: methodCode, school: school, tune: tune, year: year, month: month),
      );
    }

    return days.take(count).toList();
  }

  Future<List<PrayerDay>> _fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required String? tune,
    required int year,
    required int month,
  }) async {
    final uri = Uri.https('api.aladhan.com', '/v1/calendarByCity/$year/$month', {
      'city': city.englishCity,
      'country': city.englishCountry,
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
    return data.map((e) => PrayerDay.fromApi(e as Map<String, dynamic>)).toList();
  }
}
