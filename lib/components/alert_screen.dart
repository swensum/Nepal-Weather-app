import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A1F),
      body: SafeArea(
        child: Center(
          child: Text(
            'Alerts — designing next',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}