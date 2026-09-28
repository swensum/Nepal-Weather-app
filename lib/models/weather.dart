import 'dart:math' as math;

import 'package:weather_app_3d/helper/helpers.dart';

class Hour {
  final DateTime time;
  final double temp;
  final int pop;
  final int code;
  final bool isDay;
  const Hour(this.time, this.temp, this.pop, this.code, this.isDay);
}

class Day {
  final DateTime date;
  final int code;
  final double max, min, uv, precip, wind;
  final int pop;
  final DateTime sunrise, sunset;
  const Day({
    required this.date,
    required this.code,
    required this.max,
    required this.min,
    required this.uv,
    required this.precip,
    required this.wind,
    required this.pop,
    required this.sunrise,
    required this.sunset,
  });
}

class Wx {
  final DateTime time;
  final double temp,
      feels,
      humidity,
      precip,
      cloud,
      pressure,
      wind,
      windDir,
      gust;
  final int code;
  final bool isDay;
  final double? visKm, uv;
  final List<Hour> hours;
  final List<Day> days;
  int? aqi;
  double? pm25, pm10;

  Wx({
    required this.time,
    required this.temp,
    required this.feels,
    required this.humidity,
    required this.precip,
    required this.cloud,
    required this.pressure,
    required this.wind,
    required this.windDir,
    required this.gust,
    required this.code,
    required this.isDay,
    required this.visKm,
    required this.uv,
    required this.hours,
    required this.days,
  });

  /// Dew point (Magnus formula)
  double get dew {
    const a = 17.62, b = 243.12;
    final g = math.log(math.max(humidity, 1) / 100) + a * temp / (b + temp);
    return b * g / (a - g);
  }

  factory Wx.fromJson(Map<String, dynamic> j) {
    final cur = j['current'] as Map<String, dynamic>;
    final hr = j['hourly'] as Map<String, dynamic>;
    final dl = j['daily'] as Map<String, dynamic>;

    final times = (hr['time'] as List).cast<String>();
    final nowStr = cur['time'] as String;
    var idx = times.indexWhere((t) => t.startsWith(nowStr.substring(0, 13)));
    if (idx < 0) idx = 0;
    final end = math.min(idx + 24, times.length);

    final hours = <Hour>[
      for (int i = idx; i < end; i++)
        Hour(
          DateTime.parse(times[i]),
          toD(hr['temperature_2m'][i]),
          toD(hr['precipitation_probability'][i]).round(),
          toD(hr['weather_code'][i]).round(),
          toD(hr['is_day'][i]) == 1,
        ),
    ];

    final dTimes = (dl['time'] as List).cast<String>();
    final days = <Day>[
      for (int i = 0; i < dTimes.length; i++)
        Day(
          date: DateTime.parse(dTimes[i]),
          code: toD(dl['weather_code'][i]).round(),
          max: toD(dl['temperature_2m_max'][i]),
          min: toD(dl['temperature_2m_min'][i]),
          uv: toD(dl['uv_index_max'][i]),
          precip: toD(dl['precipitation_sum'][i]),
          wind: toD(dl['wind_speed_10m_max'][i]),
          pop: toD(dl['precipitation_probability_max'][i]).round(),
          sunrise: DateTime.parse(dl['sunrise'][i] as String),
          sunset: DateTime.parse(dl['sunset'][i] as String),
        ),
    ];

    final visM = toDn(hr['visibility'][idx]);

    return Wx(
      time: DateTime.parse(nowStr),
      temp: toD(cur['temperature_2m']),
      feels: toD(cur['apparent_temperature']),
      humidity: toD(cur['relative_humidity_2m']),
      precip: toD(cur['precipitation']),
      cloud: toD(cur['cloud_cover']),
      pressure: toD(cur['pressure_msl'], 1013),
      wind: toD(cur['wind_speed_10m']),
      windDir: toD(cur['wind_direction_10m']),
      gust: toD(cur['wind_gusts_10m']),
      code: toD(cur['weather_code']).round(),
      isDay: toD(cur['is_day']) == 1,
      visKm: visM == null ? null : visM / 1000,
      uv: toDn(hr['uv_index'][idx]),
      hours: hours,
      days: days,
    );
  }
}
