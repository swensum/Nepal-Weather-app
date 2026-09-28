import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';
import '../models/weather.dart';
import 'glass_card.dart';
import 'tilt_card.dart';

class AqiCard extends StatelessWidget {
  final Wx wx;
  const AqiCard({super.key, required this.wx});

  (String, Color) _info(int a) {
    if (a <= 50) return ('Good', const Color(0xFF4ADE80));
    if (a <= 100) return ('Moderate', const Color(0xFFFACC15));
    if (a <= 150)
      return ('Unhealthy for sensitive groups', const Color(0xFFFB923C));
    if (a <= 200) return ('Unhealthy', const Color(0xFFEF4444));
    if (a <= 300) return ('Very unhealthy', const Color(0xFFA855F7));
    return ('Hazardous', const Color(0xFF9F1239));
  }

  @override
  Widget build(BuildContext context) {
    final aqi = wx.aqi;
    final info = aqi == null ? ('Unavailable', Colors.white54) : _info(aqi);

    return TiltCard(
      radius: 28,
      max: 0.1,
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.air_rounded, size: 14, color: Colors.white60),
              const SizedBox(width: 6),
              Text('AIR QUALITY (US AQI)',
                  style: appText(11.5,
                      w: FontWeight.w700, c: Colors.white60, ls: 1.2)),
            ]),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(aqi?.toString() ?? '--',
                    style: appText(48, w: FontWeight.w300, h: 1.0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(info.$1,
                        style: appText(15, w: FontWeight.w700, c: info.$2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, box) {
              final x = ((aqi ?? 0) / 300).clamp(0.0, 1.0) * box.maxWidth;
              return SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      height: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(colors: [
                            Color(0xFF4ADE80),
                            Color(0xFFFACC15),
                            Color(0xFFFB923C),
                            Color(0xFFEF4444),
                            Color(0xFFA855F7),
                          ]),
                        ),
                      ),
                    ),
                    if (aqi != null)
                      Positioned(
                        left: x - 7,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: info.$2, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            Row(
              children: [
                _AqiStat('PM2.5', wx.pm25),
                _AqiStat('PM10', wx.pm10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AqiStat extends StatelessWidget {
  final String label;
  final double? v;
  const _AqiStat(this.label, this.v);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(children: [
        Text(label, style: appText(12.5, c: Colors.white54)),
        const SizedBox(width: 8),
        Text(v == null ? '--' : '${v!.toStringAsFixed(1)} µg/m³',
            style: appText(13.5, w: FontWeight.w700)),
      ]),
    );
  }
}
