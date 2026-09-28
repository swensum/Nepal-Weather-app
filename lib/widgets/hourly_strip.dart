import 'package:flutter/material.dart';

import 'package:weather_app_3d/helper/helpers.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/sky.dart';
import '../models/weather.dart';
import 'glass_card.dart';

class HourlyStrip extends StatefulWidget {
  final List<Hour> hours;
  const HourlyStrip({super.key, required this.hours});

  @override
  State<HourlyStrip> createState() => _HourlyStripState();
}

class _HourlyStripState extends State<HourlyStrip> {
  final ScrollController _ctrl = ScrollController();
  static const double _w = 78, _gap = 10, _pad = 16;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final vw = box.maxWidth;
      return SizedBox(
        height: 158,
        child: ListView.builder(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: _pad, vertical: 8),
          itemCount: widget.hours.length,
          itemBuilder: (context, i) {
            final h = widget.hours[i];
            final sky = skyFromCode(h.code);
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final off = _ctrl.hasClients ? _ctrl.offset : 0.0;
                final center = _pad + i * (_w + _gap) + _w / 2 - off;
                final d = ((center - vw / 2) / (vw / 2)).clamp(-1.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..rotateY(-d * 0.75)
                      ..scale(1 - d.abs() * 0.10),
                    child: SizedBox(
                      width: _w,
                      child: GlassCard(
                        radius: 24,
                        tint: i == 0 ? const Color(0xFF6EA8FF) : null,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(i == 0 ? 'Now' : h12(h.time),
                                style: appText(12.5,
                                    w: FontWeight.w600, c: Colors.white70)),
                            Icon(skyIcon(sky, h.isDay),
                                size: 30, color: skyIconColor(sky, h.isDay)),
                            Text('${h.temp.round()}°',
                                style: appText(20, w: FontWeight.w600)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.water_drop_rounded,
                                    size: 11,
                                    color: h.pop >= 10
                                        ? const Color(0xFF8CC8FF)
                                        : Colors.white24),
                                const SizedBox(width: 2),
                                Text('${h.pop}%',
                                    style: appText(11.5,
                                        c: h.pop >= 10
                                            ? const Color(0xFF8CC8FF)
                                            : Colors.white30)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
}
