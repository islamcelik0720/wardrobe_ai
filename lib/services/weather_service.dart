import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_info.dart';

class WeatherService {
  Future<WeatherInfo> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
      ].join(','),
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Hava durumu alınamadı. HTTP ${response.statusCode}');
    }

    final dynamic decodedBody;

    try {
      decodedBody = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Hava durumu servisi geçersiz yanıt döndürdü.');
    }

    if (decodedBody is! Map<String, dynamic>) {
      throw Exception('Hava durumu yanıt biçimi geçersiz.');
    }

    final current = decodedBody['current'];

    if (current is! Map<String, dynamic>) {
      throw Exception('Anlık hava durumu bilgisi bulunamadı.');
    }

    return WeatherInfo.fromMap(current);
  }
}
