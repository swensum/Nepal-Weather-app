import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A1F),
      body: SafeArea(
        child: Center(
          child: Text(
            'Settings — designing next',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }
}
