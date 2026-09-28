import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';


class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const SectionTitle(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.white60),
        const SizedBox(width: 6),
        Text(text, style: appText(12, w: FontWeight.w700, c: Colors.white60, ls: 1.4)),
      ]),
    );
  }
}
