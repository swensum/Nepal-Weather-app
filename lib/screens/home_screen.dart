import 'package:flutter/material.dart';
import 'package:weather_app_3d/components/alert_screen.dart';
import 'package:weather_app_3d/components/forecast_screen.dart';
import 'package:weather_app_3d/components/map_screen.dart';
import 'package:weather_app_3d/components/navbar.dart';
import 'package:weather_app_3d/components/setting_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    ForecastScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets each screen draw full-bleed behind the floating glass bar.
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassNavBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}