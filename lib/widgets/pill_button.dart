import 'package:flutter/material.dart';
import 'package:weather_app_3d/theme/app_theme.dart';


class PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const PillButton(this.label, this.icon, this.onTap, {this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(colors: [Color(0xFFFFAA33), Color(0xFFFF7A59)])
              : null,
          color: primary ? null : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
          border: primary ? null : Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: appText(14.5, w: FontWeight.w700)),
        ]),
      ),
    );
  }
}
