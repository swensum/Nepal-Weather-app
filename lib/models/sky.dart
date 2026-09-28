import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';


enum Sky { clear, partly, cloudy, fog, drizzle, rain, snow, storm }

Sky skyFromCode(int c) {
  if (c <= 1) return Sky.clear;
  if (c == 2) return Sky.partly;
  if (c == 3) return Sky.cloudy;
  if (c == 45 || c == 48) return Sky.fog;
  if (c >= 51 && c <= 57) return Sky.drizzle;
  if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return Sky.rain;
  if ((c >= 71 && c <= 77) || c == 85 || c == 86) return Sky.snow;
  if (c >= 95) return Sky.storm;
  return Sky.cloudy;
}

String describe(int c) {
  switch (c) {
    case 0:
      return 'Clear sky';
    case 1:
      return 'Mainly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
      return 'Foggy';
    case 48:
      return 'Rime fog';
    case 51:
      return 'Light drizzle';
    case 53:
      return 'Drizzle';
    case 55:
      return 'Heavy drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
      return 'Light rain';
    case 63:
      return 'Rain';
    case 65:
      return 'Heavy rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
      return 'Light snow';
    case 73:
      return 'Snow';
    case 75:
      return 'Heavy snow';
    case 77:
      return 'Snow grains';
    case 80:
      return 'Light showers';
    case 81:
      return 'Showers';
    case 82:
      return 'Violent showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm & hail';
    default:
      return 'Unknown';
  }
}

IconData skyIcon(Sky s, bool day) {
  switch (s) {
    case Sky.clear:
      return day ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    case Sky.partly:
      return Icons.filter_drama_rounded;
    case Sky.cloudy:
      return Icons.cloud_rounded;
    case Sky.fog:
      return Icons.blur_on_rounded;
    case Sky.drizzle:
      return Icons.grain_rounded;
    case Sky.rain:
      return Icons.water_drop_rounded;
    case Sky.snow:
      return Icons.ac_unit_rounded;
    case Sky.storm:
      return Icons.thunderstorm_rounded;
  }
}

Color skyIconColor(Sky s, bool day) {
  switch (s) {
    case Sky.clear:
      return day ? const Color(0xFFFFC233) : const Color(0xFFB8C7FF);
    case Sky.partly:
      return const Color(0xFFFFE08A);
    case Sky.cloudy:
      return const Color(0xFFCBD5E8);
    case Sky.fog:
      return const Color(0xFFC7D0DD);
    case Sky.drizzle:
    case Sky.rain:
      return const Color(0xFF7CC0FF);
    case Sky.snow:
      return const Color(0xFFE6F2FF);
    case Sky.storm:
      return const Color(0xFFFFD166);
  }
}

List<Color> skyColors(Sky s, bool day) {
  Color a, b;
  switch (s) {
    case Sky.clear:
      a = const Color(0xFF2F80ED);
      b = const Color(0xFF0E2A66);
      break;
    case Sky.partly:
      a = const Color(0xFF3B6FB6);
      b = const Color(0xFF10264F);
      break;
    case Sky.cloudy:
      a = const Color(0xFF5B6982);
      b = const Color(0xFF161E33);
      break;
    case Sky.fog:
      a = const Color(0xFF6E7C8C);
      b = const Color(0xFF1A2230);
      break;
    case Sky.drizzle:
    case Sky.rain:
      a = const Color(0xFF3A4C6B);
      b = const Color(0xFF0D1530);
      break;
    case Sky.snow:
      a = const Color(0xFF7C93B5);
      b = const Color(0xFF1A2440);
      break;
    case Sky.storm:
      a = const Color(0xFF433566);
      b = const Color(0xFF0C0C22);
      break;
  }
  if (!day) {
    a = Color.lerp(a, kBg, 0.6)!;
    b = Color.lerp(b, kBg, 0.4)!;
  }
  return [a, b];
}
