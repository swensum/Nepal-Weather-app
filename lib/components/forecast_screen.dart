import 'package:flutter/material.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A1F),
      body: SafeArea(
        child: Center(
          child: Text(
            'Forecast — designing next',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
      ),
    );
  }
}