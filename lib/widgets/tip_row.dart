import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';

import 'glass_card.dart';

class Tip {
  final IconData icon;
  final String text;
  const Tip(this.icon, this.text);
}

class TipRow extends StatelessWidget {
  final Tip tip;
  const TipRow(this.tip, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(tip.icon, color: const Color(0xFFFFD166), size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(tip.text, style: appText(13.5, w: FontWeight.w500))),
        ]),
      ),
    );
  }
}
