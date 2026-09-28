import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import 'glass_card.dart';
import 'tilt_card.dart';

class StateView extends StatelessWidget {
  final IconData icon;
  final String title, body;
  final List<Widget> actions;
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: TiltCard(
          radius: 32,
          child: GlassCard(
            radius: 32,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.4, -0.4),
                      colors: [
                        Color(0xFF7CC0FF),
                        Color(0xFF3D7BFF),
                        Color(0xFF1B2A6B)
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x663D7BFF), blurRadius: 30),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(title, style: appText(22, w: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(body,
                    textAlign: TextAlign.center,
                    style: appText(14, c: Colors.white70, h: 1.4)),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
