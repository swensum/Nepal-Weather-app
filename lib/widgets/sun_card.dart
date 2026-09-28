import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:weather_app_3d/helper/helpers.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/weather.dart';
import 'glass_card.dart';
import 'tilt_card.dart';

class _SunPainter extends CustomPainter {
  final double p; // 0..1 of the daylight period
  final bool up;
  _SunPainter(this.p, this.up);

  @override
  void paint(Canvas c, Size s) {
    const pad = 14.0;
    final baseY = s.height - 16;
    final cx = s.width / 2;
    final rx = s.width / 2 - pad;
    final ry = baseY - 14;
    final rect = Rect.fromLTRB(cx - rx, baseY - ry, cx + rx, baseY + ry);

    c.drawLine(
      Offset(pad - 6, baseY),
      Offset(s.width - pad + 6, baseY),
      Paint()
        ..strokeWidth = 1.2
        ..color = Colors.white24,
    );
    c.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white24,
    );
    if (p > 0) {
      c.drawArc(
        rect,
        math.pi,
        math.pi * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFC233),
      );
    }
    final ang = math.pi + math.pi * p;
    final pos = Offset(cx + rx * math.cos(ang), baseY + ry * math.sin(ang));
    if (up) {
      c.drawCircle(
        pos,
        14,
        Paint()
          ..color = const Color(0xFFFFB627).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      c.drawCircle(pos, 7, Paint()..color = const Color(0xFFFFD166));
    } else {
      c.drawCircle(pos, 6, Paint()..color = const Color(0xFFB8C7FF));
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter old) => old.p != p || old.up != up;
}

class SunCard extends StatelessWidget {
  final Wx wx;
  const SunCard({super.key, required this.wx});

  @override
  Widget build(BuildContext context) {
    final d = wx.days.first;
    final total = d.sunset.difference(d.sunrise).inMinutes;
    final done = wx.time.difference(d.sunrise).inMinutes;
    final up = wx.time.isAfter(d.sunrise) && wx.time.isBefore(d.sunset);
    final p = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final h = total ~/ 60, m = total % 60;

    return TiltCard(
      radius: 28,
      max: 0.1,
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.wb_twilight_rounded,
                  size: 14, color: Colors.white60),
              const SizedBox(width: 6),
              Text('SUNRISE & SUNSET',
                  style: appText(11.5,
                      w: FontWeight.w700, c: Colors.white60, ls: 1.2)),
              const Spacer(),
              Text('${h}h ${m}m of daylight',
                  style: appText(12, c: Colors.white60)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              width: double.infinity,
              child: CustomPaint(painter: _SunPainter(p, up)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(children: [
                  Text(hm(d.sunrise), style: appText(18, w: FontWeight.w700)),
                  Text('Sunrise', style: appText(11.5, c: Colors.white54)),
                ]),
                Column(children: [
                  Text(hm(d.sunset), style: appText(18, w: FontWeight.w700)),
                  Text('Sunset', style: appText(11.5, c: Colors.white54)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
