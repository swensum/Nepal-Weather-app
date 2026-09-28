import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:weather_app_3d/helper/helpers.dart';

import '../models/weather.dart';

Future<Wx> fetchWx(double lat, double lon) async {
  final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': lat.toStringAsFixed(4),
    'longitude': lon.toStringAsFixed(4),
    'current':
        'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m',
    'hourly':
        'temperature_2m,precipitation_probability,weather_code,is_day,uv_index,visibility',
    'daily':
        'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max',
    'timezone': 'auto',
    'forecast_days': '7',
  });
  final res = await http.get(uri).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) {
    throw Exception('Weather service returned ${res.statusCode}');
  }
  final wx = Wx.fromJson(jsonDecode(res.body) as Map<String, dynamic>);

  // Air quality is optional; ignore failures.
  try {
    final aq = await http
        .get(Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
          'latitude': lat.toStringAsFixed(4),
          'longitude': lon.toStringAsFixed(4),
          'current': 'us_aqi,pm2_5,pm10',
        }))
        .timeout(const Duration(seconds: 10));
    if (aq.statusCode == 200) {
      final cur = (jsonDecode(aq.body) as Map<String, dynamic>)['current']
          as Map<String, dynamic>;
      wx.aqi = toDn(cur['us_aqi'])?.round();
      wx.pm25 = toDn(cur['pm2_5']);
      wx.pm10 = toDn(cur['pm10']);
    }
  } catch (_) {}
  return wx;
}

/// Returns [city, subtitle]
Future<List<String>> reverseGeocode(double lat, double lon) async {
  try {
    final res = await http
        .get(Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
          'latitude': lat.toStringAsFixed(4),
          'longitude': lon.toStringAsFixed(4),
          'localityLanguage': 'en',
        }))
        .timeout(const Duration(seconds: 8));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    String s(String k) => (j[k] ?? '').toString();
    var city = s('city');
    if (city.isEmpty) city = s('locality');
    if (city.isEmpty) city = s('principalSubdivision');
    final sub = [s('principalSubdivision'), s('countryName')]
        .where((e) => e.isNotEmpty && e != city)
        .join(', ');
    return [city.isEmpty ? 'Your location' : city, sub];
  } catch (_) {
    return [
      'Your location',
      '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}'
    ];
  }
}
