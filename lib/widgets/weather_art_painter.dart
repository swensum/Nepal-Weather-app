import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sky.dart';

class WeatherArtPainter extends CustomPainter {
  final Sky sky;
  final bool day;
  final double t; // 0..1 looping
  WeatherArtPainter(this.sky, this.day, this.t);

  @override
  void paint(Canvas c, Size s) {
    final u = s.shortestSide;
    final bob = math.sin(t * 2 * math.pi) * u * 0.02;
    c.save();
    c.translate(0, bob);
    switch (sky) {
      case Sky.clear:
        final o1 = Offset(s.width * .5, s.height * .5);
        if (day) {
          _sun(c, o1, u * .26);
        } else {
          _moon(c, o1, u * .24);
        }
        break;
      case Sky.partly:
        final o2 = Offset(s.width * .40, s.height * .38);
        if (day) {
          _sun(c, o2, u * .20);
        } else {
          _moon(c, o2, u * .18);
        }
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .22, s.height * .40, s.width * .72, s.height * .44),
            false);
        break;
      case Sky.cloudy:
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .04, s.height * .20, s.width * .64, s.height * .36),
            true);
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .24, s.height * .38, s.width * .72, s.height * .44),
            false);
        break;
      case Sky.fog:
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .12, s.height * .14, s.width * .74, s.height * .42),
            false);
        for (int i = 0; i < 3; i++) {
          final dx = math.sin(t * 2 * math.pi + i) * u * .03;
          final y = s.height * (.64 + .1 * i);
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  s.width * (.16 + .06 * i) + dx, y, s.width * .62, u * .045),
              Radius.circular(u),
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.35 - i * 0.07),
          );
        }
        break;
      case Sky.drizzle:
      case Sky.rain:
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .10, s.height * .14, s.width * .80, s.height * .44),
            true);
        _rain(c, s, sky == Sky.rain ? 12 : 7);
        break;
      case Sky.snow:
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .10, s.height * .14, s.width * .80, s.height * .44),
            false);
        _snow(c, s, 10);
        break;
      case Sky.storm:
        _cloud(
            c,
            Rect.fromLTWH(
                s.width * .10, s.height * .12, s.width * .80, s.height * .44),
            true);
        _rain(c, s, 6);
        _bolt(c, s);
        break;
    }
    c.restore();
  }

  void _sun(Canvas c, Offset o, double r) {
    c.drawCircle(
      o,
      r * 1.15,
      Paint()
        ..color = const Color(0xFFFFB627).withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .9),
    );
    final ray = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.9)
      ..strokeWidth = r * .12
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + t * math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(o + d * (r * 1.28), o + d * (r * 1.5), ray);
    }
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFF6C9), Color(0xFFFFC93C), Color(0xFFFF8F1F)],
        ).createShader(Rect.fromCircle(center: o, radius: r)),
    );
  }

  void _moon(Canvas c, Offset o, double r) {
    c.drawCircle(
      o,
      r * 1.1,
      Paint()
        ..color = const Color(0xFF9FB4FF).withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .8),
    );
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFFFFF), Color(0xFFDDE4F7), Color(0xFF9FAED6)],
        ).createShader(Rect.fromCircle(center: o, radius: r)),
    );
    final cr = Paint()..color = const Color(0xFF7F8DB8).withValues(alpha: 0.28);
    c.drawCircle(o + Offset(r * .3, -r * .25), r * .18, cr);
    c.drawCircle(o + Offset(-r * .25, r * .2), r * .24, cr);
    c.drawCircle(o + Offset(r * .35, r * .4), r * .1, cr);
  }

  void _cloud(Canvas c, Rect b, bool dark) {
    final w = b.width, h = b.height;
    final top = dark ? const Color(0xFFB6C0D6) : Colors.white;
    final bot = dark ? const Color(0xFF7C88A6) : const Color(0xFFC9D6F0);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(b.left, b.top + h * .42, w, h * .58),
          Radius.circular(h * .29)))
      ..addOval(Rect.fromCircle(
          center: Offset(b.left + w * .32, b.top + h * .46), radius: h * .34))
      ..addOval(Rect.fromCircle(
          center: Offset(b.left + w * .60, b.top + h * .36), radius: h * .42))
      ..addOval(Rect.fromCircle(
          center: Offset(b.left + w * .80, b.top + h * .55), radius: h * .27));
    c.drawPath(
      path.shift(Offset(0, h * .08)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .12),
    );
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bot],
        ).createShader(b),
    );
  }

  void _rain(Canvas c, Size s, int n) {
    final u = s.shortestSide;
    final p = Paint()
      ..strokeWidth = u * .018
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < n; i++) {
      final x = s.width * (.24 + .55 * (i / (n - 1)));
      final ph = (t * 3 + i * .37) % 1.0;
      final y = s.height * (.64 + ph * .30);
      p.color = const Color(0xFF8EC5FF).withValues(alpha: (1 - ph) * 0.95);
      c.drawLine(Offset(x, y), Offset(x - u * .02, y + u * .07), p);
    }
  }

  void _snow(Canvas c, Size s, int n) {
    final u = s.shortestSide;
    for (int i = 0; i < n; i++) {
      final ph = (t + i * .29) % 1.0;
      final x = s.width * (.24 + .55 * (i / (n - 1))) +
          math.sin(t * 2 * math.pi + i) * u * .02;
      final y = s.height * (.62 + ph * .32);
      c.drawCircle(Offset(x, y), u * .017,
          Paint()..color = Colors.white.withValues(alpha: (1 - ph) * 0.95));
    }
  }

  void _bolt(Canvas c, Size s) {
    final bx = s.width * .48, by = s.height * .54;
    final bw = s.width * .16, bh = s.height * .36;
    final path = Path()
      ..moveTo(bx + bw * .55, by)
      ..lineTo(bx, by + bh * .55)
      ..lineTo(bx + bw * .45, by + bh * .55)
      ..lineTo(bx + bw * .2, by + bh)
      ..lineTo(bx + bw, by + bh * .4)
      ..lineTo(bx + bw * .5, by + bh * .4)
      ..close();
    final flash = math.sin(t * 2 * math.pi * 3) > 0.6 ? 1.0 : 0.65;
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.7 * flash)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    c.drawPath(path,
        Paint()..color = const Color(0xFFFFE27A).withValues(alpha: flash));
  }

  @override
  bool shouldRepaint(covariant WeatherArtPainter old) =>
      old.t != t || old.sky != sky || old.day != day;
}
