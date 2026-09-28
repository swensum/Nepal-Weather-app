import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/sky.dart';
import '../models/weather.dart';
import 'glass_card.dart';
import 'tilt_card.dart';
import 'weather_art_painter.dart';

class HeroCard extends StatelessWidget {
  final Wx wx;
  final Animation<double> anim;
  const HeroCard({required this.wx, required this.anim});

  @override
  Widget build(BuildContext context) {
    final sky = skyFromCode(wx.code);
    final today = wx.days.first;
    final pop = wx.hours.isEmpty ? today.pop : wx.hours.first.pop;

    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: TiltCard(
        radius: 34,
        max: 0.16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlassCard(
              radius: 34,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NOW',
                                style: appText(12,
                                    w: FontWeight.w700, c: Colors.white60, ls: 1.6)),
                            Text('${wx.temp.round()}°',
                                style: appText(96, w: FontWeight.w200, h: 1.0)),
                            Text(describe(wx.code),
                                style: appText(20, w: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              'H ${today.max.round()}°   L ${today.min.round()}°   ·   Feels ${wx.feels.round()}°',
                              style: appText(13, c: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 110),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MiniStat(Icons.water_drop_rounded, '$pop%', 'Rain'),
                      _MiniStat(Icons.air_rounded, '${wx.wind.round()} km/h', 'Wind'),
                      _MiniStat(Icons.opacity_rounded, '${wx.humidity.round()}%', 'Humidity'),
                    ],
                  ),
                ],
              ),
            ),
            // Floating art: pops out of the card in 3D when tilted.
            Positioned(
              right: -6,
              top: -40,
              child: IgnorePointer(
                child: Transform(
                  transform: Matrix4.identity()..translate(0.0, 0.0, -80.0),
                  child: SizedBox(
                    width: 175,
                    height: 175,
                    child: AnimatedBuilder(
                      animation: anim,
                      builder: (_, __) => CustomPaint(
                        painter: WeatherArtPainter(sky, wx.isDay, anim.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _MiniStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 18, color: const Color(0xFF8CC8FF)),
        const SizedBox(height: 4),
        Text(value, style: appText(15, w: FontWeight.w700)),
        Text(label, style: appText(11.5, c: Colors.white54)),
      ]),
    );
  }
}
