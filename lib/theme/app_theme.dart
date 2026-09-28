import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static LinearGradient skyGradient({
    required bool isDay,
    required int weatherCode,
  }) {
    // Thunderstorm — near-black indigo with a violet undertone
    if (weatherCode >= 95) {
      return const LinearGradient(
        colors: [Color(0xFF0D0B1E), Color(0xFF261C3D), Color(0xFF3F2E5C)],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    // Snow — cool slate blue fading to soft ice white
    if (weatherCode >= 71 && weatherCode <= 77) {
      return const LinearGradient(
        colors: [Color(0xFF3E5C76), Color(0xFF748CAB), Color(0xFFD8E2E9)],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    // Rain / drizzle — deep teal-slate, moody but not muddy
    if ((weatherCode >= 51 && weatherCode <= 67) ||
        (weatherCode >= 80 && weatherCode <= 82)) {
      return const LinearGradient(
        colors: [Color(0xFF11212D), Color(0xFF1E3A46), Color(0xFF3A5A6B)],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    // Cloudy
    if (weatherCode >= 2 && weatherCode <= 48) {
      return isDay
          ? const LinearGradient(
              colors: [Color(0xFF4B6382), Color(0xFF7C93AD), Color(0xFFB9C6D6)],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            )
          : const LinearGradient(
              colors: [Color(0xFF0C1420), Color(0xFF1B2A3D), Color(0xFF2F435A)],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            );
    }
    // Clear — rich, saturated but not neon; a proper "premium sky"
    return isDay
        ? const LinearGradient(
            colors: [Color(0xFF0A4B9E), Color(0xFF1E7FD6), Color(0xFF5FB4E5)],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFF060A1F), Color(0xFF141B3C), Color(0xFF2A2456)],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
  }

  // ---------------------------------------------------------------------
  // Glass card palette
  // ---------------------------------------------------------------------
  static const Color glassFill = Color(0x29FFFFFF); // white @ 16%
  static const Color glassBorder = Color(0x4DFFFFFF); // white @ 30%
  static const Color glassShadow = Color(0x66000000); // black @ 40%

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xE0FFFFFF); // white @ 88%
  static const Color textTertiary = Color(0x99FFFFFF); // white @ 60%

  // Warm amber-gold accent — the one warm color against all the cool
  // backgrounds, so it's used for temperature/highlights and pops hard.
  static const Color accent = Color(0xFFFFB238);
  static const Color accentSoft = Color(0xFFFFD98E);

  static const Color danger = Color(0xFFFF6B6B);
  static const Color good = Color(0xFF57D9A3);
  static const Color info = Color(0xFF6EC6FF);

  // ---------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------
  static TextTheme get textTheme => GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 88,
          fontWeight: FontWeight.w200,
          color: textPrimary,
          letterSpacing: -2,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      );

  static ThemeData get themeData => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060A1F),
        textTheme: textTheme,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: good,
          error: danger,
        ),
      );
}

const Color kBg = Color(0xFF060A1F);
const double kFallbackLat = 27.7172; // Kathmandu
const double kFallbackLon = 85.3240;

TextStyle appText(double size,
        {FontWeight w = FontWeight.w400,
        Color c = Colors.white,
        double? ls,
        double? h}) =>
    TextStyle(
        fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);
