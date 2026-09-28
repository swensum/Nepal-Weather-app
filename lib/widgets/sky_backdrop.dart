import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/sky.dart';

class SkyBackdrop extends StatelessWidget {
  final Sky sky;
  final bool day;
  final Animation<double> anim;
  const SkyBackdrop({super.key, required this.sky, required this.day, required this.anim});

  @override
  Widget build(BuildContext context) {
    final c = skyColors(sky, day);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c[0], c[1], kBg],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) {
          final t = anim.value * 2 * math.pi;
          Widget orb(double phase, Color col, double size, double ax, double ay) {
            return Align(
              alignment: Alignment(
                ax + 0.35 * math.sin(t + phase),
                ay + 0.25 * math.cos(t + phase),
              ),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [col.withValues(alpha:0.35), col.withValues(alpha:0)],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              if (!day && (sky == Sky.clear || sky == Sky.partly))
                Positioned.fill(
                  child: CustomPaint(painter: _StarsPainter(anim.value)),
                ),
              orb(0, c[0], 420, -0.8, -0.6),
              orb(2, const Color(0xFF7B5CFF), 360, 0.9, 0.1),
              orb(4, const Color(0xFF00C2FF), 320, -0.6, 0.8),
            ],
          );
        },
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double t;
  _StarsPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(4);
    for (int i = 0; i < 70; i++) {
      final dx = r.nextDouble() * s.width;
      final dy = r.nextDouble() * s.height * 0.6;
      final ph = r.nextDouble() * 6.28;
      final rad = 0.6 + r.nextDouble() * 1.1;
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 2 + ph));
      c.drawCircle(Offset(dx, dy), rad,
          Paint()..color = Colors.white.withValues(alpha:tw * 0.8));
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => old.t != t;
}
