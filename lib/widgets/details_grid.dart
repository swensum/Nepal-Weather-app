import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app_3d/helper/helpers.dart';

import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/weather.dart';
import 'glass_card.dart';
import 'tilt_card.dart';

Color _lerpList(List<Color> cs, double t) {
  final x = t.clamp(0.0, 1.0) * (cs.length - 1);
  final i = x.floor().clamp(0, cs.length - 2);
  return Color.lerp(cs[i], cs[i + 1], x - i)!;
}

class _GaugePainter extends CustomPainter {
  final double v;
  final List<Color> colors;
  _GaugePainter(this.v, this.colors);

  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: r);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.12);
    c.drawArc(rect, 3 * math.pi / 4, 3 * math.pi / 2, false, track);
    final val = v.clamp(0.0, 1.0);
    if (val > 0) {
      final col = _lerpList(colors, val);
      c.drawArc(
        rect,
        3 * math.pi / 4,
        3 * math.pi / 2 * val,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..color = col.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      c.drawArc(
        rect,
        3 * math.pi / 4,
        3 * math.pi / 2 * val,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..color = col,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.v != v;
}

class _CompassPainter extends CustomPainter {
  final double deg; // direction wind comes FROM
  _CompassPainter(this.deg);

  void _label(Canvas c, String t, Offset o, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: appText(11, w: FontWeight.w800, c: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.shortestSide / 2 - 4;
    c.drawCircle(o, r, Paint()..color = Colors.white.withOpacity(0.06));
    c.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white24,
    );
    for (int i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final long = i % 3 == 0;
      final d = Offset(math.sin(a), -math.cos(a));
      c.drawLine(
        o + d * (r - (long ? 9 : 5)),
        o + d * (r - 1),
        Paint()
          ..strokeWidth = long ? 1.6 : 1
          ..color = Colors.white.withOpacity(long ? 0.5 : 0.25),
      );
    }
    _label(c, 'N', o + Offset(0, -r + 18), const Color(0xFFFF6B6B));
    _label(c, 'E', o + Offset(r - 16, 0), Colors.white54);
    _label(c, 'S', o + Offset(0, r - 16), Colors.white54);
    _label(c, 'W', o + Offset(-r + 16, 0), Colors.white54);

    // arrow shows where the wind is blowing TO
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate((deg + 180) * math.pi / 180);
    final arrow = Path()
      ..moveTo(0, -r * .52)
      ..lineTo(r * .13, r * .14)
      ..lineTo(0, r * .04)
      ..lineTo(-r * .13, r * .14)
      ..close();
    c.drawPath(
      arrow,
      Paint()
        ..color = const Color(0xFF6EA8FF).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawPath(arrow, Paint()..color = const Color(0xFF8CC8FF));
    c.restore();
    c.drawCircle(o, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.deg != deg;
}

class _DetailCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final Widget child;
  final String footer;
  const _DetailCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.child,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TiltCard(
        radius: 24,
        child: GlassCard(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: SizedBox(
            height: 168,
            child: Column(
              children: [
                Row(children: [
                  Icon(icon, size: 14, color: Colors.white60),
                  const SizedBox(width: 6),
                  Text(title, style: appText(11.5, w: FontWeight.w700, c: Colors.white60, ls: 1.2)),
                ]),
                Expanded(child: Center(child: child)),
                Text(footer,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: appText(12.5, c: Colors.white70, w: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailsGrid extends StatelessWidget {
  final Wx wx;
  const DetailsGrid({super.key, required this.wx});

  Widget _gauge(double v, List<Color> cols, String big, String small) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(96, 96), painter: _GaugePainter(v, cols)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(big, style: appText(21, w: FontWeight.w700)),
              Text(small, style: appText(10.5, c: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }

  String _uvLevel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very high';
    return 'Extreme';
  }

  String _visLabel(double km) {
    if (km >= 10) return 'Excellent visibility';
    if (km >= 5) return 'Good visibility';
    if (km >= 2) return 'Moderate visibility';
    return 'Poor visibility';
  }

  @override
  Widget build(BuildContext context) {
    final today = wx.days.first;
    final uv = math.max(wx.uv ?? today.uv, 0).toDouble();
    final pressureLabel = wx.pressure < 1005
        ? 'Low pressure'
        : (wx.pressure > 1020 ? 'High pressure' : 'Normal pressure');
    final diff = wx.feels - wx.temp;
    final feelsText = diff.abs() < 1.5
        ? 'Similar to actual'
        : (diff > 0 ? 'Feels warmer' : 'Feels cooler');

    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _DetailCard(
            width: w,
            icon: Icons.air_rounded,
            title: 'WIND',
            footer:
                '${wx.wind.round()} km/h from ${dirText(wx.windDir)}\nGusts ${wx.gust.round()} km/h',
            child: SizedBox(
              width: 92,
              height: 92,
              child: CustomPaint(painter: _CompassPainter(wx.windDir)),
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.compress_rounded,
            title: 'PRESSURE',
            footer: pressureLabel,
            child: _gauge(
              (wx.pressure - 980) / 60,
              const [Color(0xFF4FC3F7), Color(0xFF7CE0A6), Color(0xFFFFD166)],
              wx.pressure.round().toString(),
              'hPa',
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.opacity_rounded,
            title: 'HUMIDITY',
            footer: 'Dew point ${wx.dew.round()}°',
            child: _gauge(
              wx.humidity / 100,
              const [Color(0xFF4FC3F7), Color(0xFF3D7BFF), Color(0xFF7B5CFF)],
              '${wx.humidity.round()}',
              '%',
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.light_mode_rounded,
            title: 'UV INDEX',
            footer: _uvLevel(uv),
            child: _gauge(
              uv / 11,
              const [Color(0xFF7CE0A6), Color(0xFFFFD166), Color(0xFFFF8A4C), Color(0xFFE5484D)],
              uv.toStringAsFixed(uv < 10 ? 1 : 0),
              'of 11+',
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.visibility_rounded,
            title: 'VISIBILITY',
            footer: wx.visKm == null ? 'No data' : _visLabel(wx.visKm!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wx.visKm == null
                      ? '--'
                      : (wx.visKm! >= 10
                          ? '${wx.visKm!.round()}'
                          : wx.visKm!.toStringAsFixed(1)),
                  style: appText(40, w: FontWeight.w300),
                ),
                Text('km', style: appText(13, c: Colors.white54)),
              ],
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.cloud_rounded,
            title: 'CLOUD COVER',
            footer: wx.cloud < 20
                ? 'Mostly clear'
                : (wx.cloud < 60 ? 'Partly cloudy' : 'Mostly cloudy'),
            child: _gauge(
              wx.cloud / 100,
              const [Color(0xFF9FB4D8), Color(0xFFE6EEFF)],
              '${wx.cloud.round()}',
              '%',
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.water_drop_rounded,
            title: 'PRECIPITATION',
            footer:
                'Today ${today.precip.toStringAsFixed(1)} mm · ${today.pop}% chance',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(wx.precip.toStringAsFixed(1), style: appText(40, w: FontWeight.w300)),
                Text('mm now', style: appText(13, c: Colors.white54)),
              ],
            ),
          ),
          _DetailCard(
            width: w,
            icon: Icons.thermostat_rounded,
            title: 'FEELS LIKE',
            footer: feelsText,
            child: Text('${wx.feels.round()}°', style: appText(46, w: FontWeight.w200)),
          ),
        ],
      );
    });
  }
}
