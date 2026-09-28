import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app_3d/models/sky.dart';
import 'package:weather_app_3d/models/weather.dart';
import 'package:weather_app_3d/services/weather_service.dart';
import 'package:weather_app_3d/theme/app_theme.dart';
import 'package:weather_app_3d/widgets/aqi_card.dart';
import 'package:weather_app_3d/widgets/daily_card.dart';
import 'package:weather_app_3d/widgets/details_grid.dart';
import 'package:weather_app_3d/widgets/glass_card.dart';
import 'package:weather_app_3d/widgets/hero_card.dart';
import 'package:weather_app_3d/widgets/hourly_strip.dart';
import 'package:weather_app_3d/widgets/loading_view.dart';
import 'package:weather_app_3d/widgets/pill_button.dart';
import 'package:weather_app_3d/widgets/reveal_in.dart';
import 'package:weather_app_3d/widgets/section_title.dart';
import 'package:weather_app_3d/widgets/sky_backdrop.dart';
import 'package:weather_app_3d/widgets/state_view.dart';
import 'package:weather_app_3d/widgets/sun_card.dart';
import 'package:weather_app_3d/widgets/tip_row.dart';


enum _Status { loading, denied, deniedForever, serviceOff, error, ready }

class ForecastScreen extends StatefulWidget {
  /// Space for your bottom navigation bar.
  final double bottomInset;
  const ForecastScreen({super.key, this.bottomInset = 110});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _anim;
  _Status _status = _Status.loading;
  String _error = '';
  Wx? _wx;
  String _place = '';
  String _sub = '';
  bool _fallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anim.dispose();
    super.dispose();
  }

  // Coming back from the settings app -> retry automatically.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_status == _Status.deniedForever ||
            _status == _Status.serviceOff ||
            _status == _Status.denied)) {
      _load();
    }
  }

  Future<Position?> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) setState(() => _status = _Status.serviceOff);
      return null;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission(); // system dialog
    }
    if (perm == LocationPermission.denied) {
      if (mounted) setState(() => _status = _Status.denied);
      return null;
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) setState(() => _status = _Status.deniedForever);
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  Future<void> _load({bool silent = false, bool fallback = false}) async {
    if (!silent && mounted) setState(() => _status = _Status.loading);
    try {
      double lat, lon;
      if (fallback) {
        lat = kFallbackLat;
        lon = kFallbackLon;
      } else {
        final p = await _position();
        if (p == null) return; // status already set
        lat = p.latitude;
        lon = p.longitude;
      }
      final wxF = fetchWx(lat, lon);
      final placeF = reverseGeocode(lat, lon);
      final wx = await wxF;
      final place = await placeF;
      if (!mounted) return;
      setState(() {
        _wx = wx;
        _place = fallback ? 'Kathmandu' : place[0];
        _sub = fallback ? 'Nepal · default location' : place[1];
        _fallback = fallback;
        _status = _Status.ready;
      });
    } catch (e) {
      debugPrint('Forecast error: $e');
      if (!mounted) return;
      if (silent && _wx != null) return; // keep old data on refresh failure
      setState(() {
        _error = 'Could not get the forecast. Check your connection and try again.';
        _status = _Status.error;
      });
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final wx = _wx;
    final ready = _status == _Status.ready && wx != null;
    final sky = ready ? skyFromCode(wx.code) : Sky.clear;
    final day = ready ? wx.isDay : false;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          SkyBackdrop(sky: sky, day: day, anim: _anim),
          SafeArea(bottom: false, child: _body(wx)),
        ],
      ),
    );
  }

  Widget _body(Wx? wx) {
    switch (_status) {
      case _Status.loading:
        return LoadingView(anim: _anim);
      case _Status.denied:
        return StateView(
          icon: Icons.location_on_rounded,
          title: 'Allow location',
          body:
              'Turn on location to see the weather report for exactly where you are.',
          actions: [
            PillButton('Allow location', Icons.my_location_rounded, () => _load(),
                primary: true),
            PillButton('Use Kathmandu', Icons.location_city_rounded,
                () => _load(fallback: true)),
          ],
        );
      case _Status.deniedForever:
        return StateView(
          icon: Icons.location_off_rounded,
          title: 'Location is blocked',
          body:
              'Location permission was denied. Open settings and allow "While Using the App" for this app.',
          actions: [
            PillButton('Open settings', Icons.settings_rounded,
                () => Geolocator.openAppSettings(),
                primary: true),
            PillButton('Use Kathmandu', Icons.location_city_rounded,
                () => _load(fallback: true)),
          ],
        );
      case _Status.serviceOff:
        return StateView(
          icon: Icons.location_disabled_rounded,
          title: 'Location services are off',
          body: 'Turn on location services on your phone to get local weather.',
          actions: [
            PillButton('Open location settings', Icons.settings_rounded,
                () => Geolocator.openLocationSettings(),
                primary: true),
            PillButton('Use Kathmandu', Icons.location_city_rounded,
                () => _load(fallback: true)),
          ],
        );
      case _Status.error:
        return StateView(
          icon: Icons.cloud_off_rounded,
          title: 'Something went wrong',
          body: _error,
          actions: [
            PillButton('Try again', Icons.refresh_rounded, () => _load(),
                primary: true),
            PillButton('Use Kathmandu', Icons.location_city_rounded,
                () => _load(fallback: true)),
          ],
        );
      case _Status.ready:
        return _content(wx!);
    }
  }

  List<Tip> _tips(Wx wx) {
    final tips = <Tip>[];
    final pop = wx.hours.take(12).fold<int>(0, (m, h) => math.max(m, h.pop));
    final uv = math.max(wx.uv ?? 0, 0);
    if (wx.code >= 95) {
      tips.add(const Tip(Icons.thunderstorm_rounded,
          'Thunderstorms nearby - stay indoors if you can'));
    }
    if (pop >= 60) {
      tips.add(Tip(Icons.umbrella_rounded,
          'Carry an umbrella - up to $pop% rain chance in the next 12 hours'));
    }
    if (uv >= 6) {
      tips.add(const Tip(
          Icons.light_mode_rounded, 'High UV - use sunscreen and seek shade at midday'));
    }
    if (wx.gust >= 50) {
      tips.add(Tip(Icons.air_rounded, 'Strong gusts up to ${wx.gust.round()} km/h'));
    }
    if (wx.temp >= 35) {
      tips.add(const Tip(Icons.thermostat_rounded, 'Very hot - stay hydrated'));
    } else if (wx.temp <= 5) {
      tips.add(const Tip(Icons.ac_unit_rounded, 'Cold - dress warmly'));
    }
    final aqi = wx.aqi;
    if (aqi != null && aqi >= 151) {
      tips.add(const Tip(Icons.masks_rounded, 'Poor air - limit time outdoors'));
    } else if (aqi != null && aqi >= 101) {
      tips.add(const Tip(Icons.masks_rounded,
          'Air is unhealthy for sensitive groups'));
    }
    if (tips.isEmpty) {
      tips.add(const Tip(Icons.check_circle_rounded, 'Conditions look comfortable'));
    }
    return tips.take(3).toList();
  }

  Widget _content(Wx wx) {
    final items = <Widget>[
      _header(),
      HeroCard(wx: wx, anim: _anim),
      Column(
        children: [for (final t in _tips(wx)) TipRow(t)],
      ),
      const SectionTitle(Icons.schedule_rounded, 'NEXT 24 HOURS'),
      HourlyStrip(hours: wx.hours),
      const SectionTitle(Icons.calendar_month_rounded, '7-DAY FORECAST'),
      DailyCard(days: wx.days),
      const SectionTitle(Icons.grid_view_rounded, 'DETAILS'),
      DetailsGrid(wx: wx),
      SunCard(wx: wx),
      AqiCard(wx: wx),
      Center(
        child: Text('Weather data by Open-Meteo.com',
            style: appText(11, c: Colors.white38)),
      ),
    ];

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: const Color(0xFF1B2447),
      onRefresh: () => _load(silent: true, fallback: _fallback),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, widget.bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: RevealIn(i: i, child: items[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(24, w: FontWeight.w700)),
              if (_sub.isNotEmpty)
                Text(_sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appText(12.5, c: Colors.white60)),
            ],
          ),
        ),
        if (_fallback)
          GestureDetector(
            onTap: () => _load(),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3D7BFF).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF6EA8FF)),
              ),
              child: Row(children: [
                const Icon(Icons.my_location_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text('Use GPS', style: appText(11.5, w: FontWeight.w600)),
              ]),
            ),
          ),
        GestureDetector(
          onTap: () => _load(fallback: _fallback),
          child: const GlassCard(
            radius: 14,
            padding: EdgeInsets.all(10),
            child: Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}