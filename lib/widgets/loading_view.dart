import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';


class LoadingView extends StatelessWidget {
  final Animation<double> anim;
  const LoadingView({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: anim,
            builder: (_, __) {
              final s = 1 + 0.08 * math.sin(anim.value * 2 * math.pi * 4);
              return Transform.scale(
                scale: s,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      colors: [Color(0xFFFFF3B0), Color(0xFFFFC233), Color(0xFFFF8A00)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x88FFB627), blurRadius: 40),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          Text('Finding your location...', style: appText(15, c: Colors.white70)),
        ],
      ),
    );
  }
}
