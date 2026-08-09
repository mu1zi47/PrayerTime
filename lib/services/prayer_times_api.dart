import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/prayer_day.dart';

/// Thrown on any failure to fetch/parse prayer times, with a message
/// already suitable to show the user (in Russian).
class PrayerApiException implements Exception {
  final String message;

  const PrayerApiException(this.message);

  @override
  String toString() => message;
}

/// Client for the free, keyless Al Adhan API (api.aladhan.com).
class PrayerTimesApi {
  PrayerTimesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches [count] consecutive days of prayer times starting at [from]
  /// (a city-local, time-of-day-ignored date), rolling over into
  /// subsequent months as needed.
  Future<List<PrayerDay>> fetchUpcomingDays({
    required City city,
    required int methodCode,
    required int school,
    required DateTime from,
    int count = 10,
  }) async {
    var year = from.year;
    var month = from.month;

    var days = (await _fetchMonth(city: city, methodCode: methodCode, school: school, year: year, month: month))
        .where((d) => !d.date.isBefore(from))
        .toList();

    while (days.length < count) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      days.addAll(await _fetchMonth(city: city, methodCode: methodCode, school: school, year: year, month: month));
    }

    return days.take(count).toList();
  }

  Future<List<PrayerDay>> _fetchMonth({
    required City city,
    required int methodCode,
    required int school,
    required int year,
    required int month,
  }) async {
    final uri = Uri.https('api.aladhan.com', '/v1/calendarByCity/$year/$month', {
      'city': city.englishCity,
      'country': city.englishCountry,
      'method': '$methodCode',
      'school': '$school',
    });

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const PrayerApiException('Превышено время ожидания. Проверьте интернет-соединение.');
    } on SocketException {
      throw const PrayerApiException('Нет соединения с интернетом.');
    }

    if (response.statusCode != 200) {
      throw const PrayerApiException('Сервис времён намаза временно недоступен.');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const PrayerApiException('Не удалось разобрать ответ сервиса.');
    }

    if (body['code'] != 200) {
      throw const PrayerApiException('Не удалось получить времена намаза.');
    }

    final data = body['data'] as List;
    return data.map((e) => PrayerDay.fromApi(e as Map<String, dynamic>)).toList();
  }
}
