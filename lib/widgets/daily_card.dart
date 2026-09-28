import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app_3d/helper/helpers.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import '../models/sky.dart';
import '../models/weather.dart';
import 'glass_card.dart';
import 'tilt_card.dart';

class DailyCard extends StatelessWidget {
  final List<Day> days;
  const DailyCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final lo = days.map((d) => d.min).reduce(math.min);
    final hi = days.map((d) => d.max).reduce(math.max);
    final range = math.max(hi - lo, 1);

    return TiltCard(
      radius: 28,
      max: 0.08,
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            for (int i = 0; i < days.length; i++) ...[
              Builder(builder: (context) {
                final d = days[i];
                final sky = skyFromCode(d.code);
                final a = (d.min - lo) / range;
                final b = (d.max - lo) / range;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(i == 0 ? 'Today' : kDays[d.date.weekday - 1],
                            style: appText(15, w: FontWeight.w600)),
                      ),
                      Icon(skyIcon(sky, true), size: 24, color: skyIconColor(sky, true)),
                      SizedBox(
                        width: 44,
                        child: Text(
                          d.pop >= 10 ? '${d.pop}%' : '',
                          textAlign: TextAlign.center,
                          style: appText(11.5, c: const Color(0xFF8CC8FF), w: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text('${d.min.round()}°',
                            textAlign: TextAlign.right,
                            style: appText(14, c: Colors.white60)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(builder: (context, box) {
                          final w = box.maxWidth;
                          return SizedBox(
                            height: 6,
                            child: Stack(children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Positioned(
                                left: a * w,
                                width: math.max((b - a) * w, 8.0),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF4FC3F7),
                                      Color(0xFFFFD166),
                                      Color(0xFFFF8A4C),
                                    ]),
                                  ),
                                ),
                              ),
                            ]),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text('${d.max.round()}°',
                            style: appText(14, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }),
              if (i != days.length - 1) Container(height: 1, color: Colors.white10),
            ],
          ],
        ),
      ),
    );
  }
}
