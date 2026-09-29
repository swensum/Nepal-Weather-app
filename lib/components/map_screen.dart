import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const String kOwmKey = String.fromEnvironment('OWM_KEY');
const String kTomorrowApiKey = String.fromEnvironment('TOMORROW_KEY');

const int kForecastStepMinutes = 30;
const int kForecastHours = 2;
const int kTomorrowMaxNativeZoom = 8;
const int kOwmMaxNativeZoom = 9;

const int kMaxRadarFrames = 8; 
const int kStageDelayMs = 350; 

const String kUserAgent = 'com.example.weather_app_3d';

enum WeatherLayer {
  radar('Rain Radar', Icons.water_drop_rounded, null),
  temperature('Temperature', Icons.thermostat_rounded, 'temp_new'),
  clouds('Clouds', Icons.cloud_rounded, 'clouds_new'),
  wind('Wind', Icons.air_rounded, 'wind_new'),
  pressure('Pressure', Icons.speed_rounded, 'pressure_new');

  final String label;
  final IconData icon;
  final String? owmId; // null for radar
  const WeatherLayer(this.label, this.icon, this.owmId);
}

class BaseStyle {
  final String name;
  final IconData icon;
  final String baseUrl;
  final String? labelsUrl;
  final int baseNativeZoom;
  final int labelsNativeZoom;

  const BaseStyle({
    required this.name,
    required this.icon,
    required this.baseUrl,
    required this.labelsUrl,
    required this.baseNativeZoom,
    required this.labelsNativeZoom,
  });
}

const String _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';

const List<BaseStyle> kBaseStyles = [
  BaseStyle(
    name: 'Dark',
    icon: Icons.dark_mode_rounded,
    baseUrl: '$_esri/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    labelsUrl:
        '$_esri/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    baseNativeZoom: 16,
    labelsNativeZoom: 16,
  ),
  BaseStyle(
    name: 'Satellite',
    icon: Icons.satellite_alt_rounded,
    baseUrl: '$_esri/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    labelsUrl:
        '$_esri/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
    baseNativeZoom: 17,
    labelsNativeZoom: 16,
  ),
  BaseStyle(
    name: 'Light',
    icon: Icons.light_mode_rounded,
    baseUrl: '$_esri/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    labelsUrl:
        '$_esri/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
    baseNativeZoom: 16,
    labelsNativeZoom: 16,
  ),
];

/// One animation frame (radar or forecast).
class MapFrame {
  final DateTime time;
  final String urlTemplate;
  final bool isForecast;
  final int maxNativeZoom;

  const MapFrame({
    required this.time,
    required this.urlTemplate,
    required this.isForecast,
    required this.maxNativeZoom,
  });
}

class MapScreen extends StatefulWidget {
 
  final double bottomInset;

  const MapScreen({super.key, this.bottomInset = 100});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _map = MapController();

  static const LatLng _nepal = LatLng(28.3949, 84.1240);
  static const double _defaultZoom = 5.0;

  List<MapFrame> _frames = [];
  int _index = 0;
  int _liveIndex = 0;

  WeatherLayer _layer = WeatherLayer.radar;
  BaseStyle _base = kBaseStyles.first;

  bool _loading = true;
  bool _preparing = false;
  String? _error;
  bool _playing = false;
  bool _showOverlay = true;
  Timer? _timer;
  final Set<int> _mounted = {};
  Timer? _stageTimer;
  Timer? _restageTimer;
  bool _ready = false;

  int get _totalPast => _frames.where((f) => !f.isForecast).length;

  @override
  void initState() {
    super.initState();
    
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = 400 << 20;
    cache.maximumSize = 3000;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stageTimer?.cancel();
    _restageTimer?.cancel();
    super.dispose();
  }

  void _startStaging() {
    _stageTimer?.cancel();
    if (_frames.isEmpty || _layer != WeatherLayer.radar) return;
    _stop();

    final order = <int>[
      if (!_frames[_index].isForecast) _index,
      for (int i = _frames.length - 1; i >= 0; i--)
        if (!_frames[i].isForecast && i != _index) i,
    ];
    if (order.isEmpty) {
      setState(() {
        _mounted.clear();
        _ready = true;
        _preparing = false;
      });
      return;
    }

    setState(() {
      _mounted
        ..clear()
        ..add(order.first);
      _ready = false;
      _preparing = true;
    });

    int n = 1;
    _stageTimer =
        Timer.periodic(const Duration(milliseconds: kStageDelayMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (n < order.length) {
        setState(() => _mounted.add(order[n]));
      }
      n++;
      
      if (n >= order.length + 3) {
        t.cancel();
        setState(() {
          _ready = true;
          _preparing = false;
        });
      }
    });
  }
  void _onViewChanging() {
    if (_layer != WeatherLayer.radar || _frames.isEmpty) return;
    _stop();
    if (_mounted.length > 1 || _ready) {
      setState(() {
        _mounted.removeWhere((i) => i != _index);
        _ready = false;
        _preparing = true;
      });
    }
    _restageTimer?.cancel();
    _restageTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _startStaging();
    });
  }

  // ---------------------------------------------------------------- data

  Future<void> _load() async {
    _stop();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('RainViewer returned ${res.statusCode}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final String host = data['host'] as String;
      final radar = (data['radar'] ?? {}) as Map<String, dynamic>;
      final List allPast = (radar['past'] ?? []) as List;
      final List past = allPast.length > kMaxRadarFrames
          ? allPast.sublist(allPast.length - kMaxRadarFrames)
          : allPast;
      final List nowcast = (radar['nowcast'] ?? []) as List;

      MapFrame rv(dynamic item, bool forecast) {
        final int t = item['time'] as int;
        final String path = item['path'] as String;
        return MapFrame(
          time: DateTime.fromMillisecondsSinceEpoch(t * 1000),
          // 256px tiles, colour scheme 2 (Universal Blue), smooth=1, snow=1
          urlTemplate: '$host$path/256/{z}/{x}/{y}/2/1_1.png',
          isForecast: forecast,
          maxNativeZoom: 7, // RainViewer public API limit
        );
      }

      final frames = <MapFrame>[
        for (final p in past) rv(p, false),
        for (final n in nowcast) rv(n, true),
      ];

      if (frames.isEmpty) throw Exception('No radar frames available');

      final liveIndex = past.isEmpty ? 0 : past.length - 1;

      // Optional Tomorrow.io forecast frames
      if (kTomorrowApiKey.isNotEmpty && nowcast.isEmpty) {
        final base = frames[liveIndex].time;
        const steps = (kForecastHours * 60) ~/ kForecastStepMinutes;
        for (int i = 1; i <= steps; i++) {
          final t = base.add(Duration(minutes: kForecastStepMinutes * i));
          final u = t.toUtc();
          final ts = DateTime.utc(u.year, u.month, u.day, u.hour, u.minute)
              .toIso8601String()
              .replaceAll('.000Z', 'Z');
          frames.add(MapFrame(
            time: t,
            urlTemplate: 'https://api.tomorrow.io/v4/map/tile/{z}/{x}/{y}/'
                'precipitationIntensity/$ts.png?apikey=$kTomorrowApiKey',
            isForecast: true,
            maxNativeZoom: kTomorrowMaxNativeZoom,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _frames = frames;
        _liveIndex = liveIndex;
        _index = liveIndex;
        _loading = false;
      });
      _startStaging();
    } catch (e) {
      debugPrint('Radar load error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load radar. Tap to retry.';
      });
    }
  }

  // ------------------------------------------------------------ controls

  void _togglePlay() {
    if (_playing) {
      _stop();
      return;
    }
    if (_frames.length < 2 || _layer != WeatherLayer.radar || !_ready) return;

    setState(() {
      _playing = true;
      _showOverlay = true;
      if (_index >= _frames.length - 1) _index = 0;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _playing) setState(() => _playing = false);
  }

  void _zoom(double delta) {
    final cam = _map.camera;
    _onViewChanging();
    _map.move(cam.center, (cam.zoom + delta).clamp(3.0, 18.0));
  }

  void _selectLayer(WeatherLayer l) {
    if (l != WeatherLayer.radar) {
      _stop();
      _stageTimer?.cancel();
    }
    setState(() {
      _layer = l;
      _showOverlay = true;
    
      if (l != WeatherLayer.radar && _base.name == 'Satellite') {
        _base = kBaseStyles.first;
      }
    });
    if (l == WeatherLayer.radar) _startStaging();
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _startStaging();
    } else {
      _stop();
      _stageTimer?.cancel();
    }
  }

  void _openLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LayerSheet(
        selectedLayer: _layer,
        selectedBase: _base,
        hasOwmKey: kOwmKey.isNotEmpty,
        onLayer: (l) {
          _selectLayer(l);
          Navigator.pop(context);
        },
        onBase: (b) {
          setState(() => _base = b);
          Navigator.pop(context);
        },
      ),
    );
  }
  bool _shouldBuild(int i) {
    if (!_frames[i].isForecast) return _mounted.contains(i) || i == _index;
    return (i - _index).abs() <= 1;
  }

  String _clock(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  String _relative(int i) {
    if (_frames.isEmpty) return '';
    final diff = _frames[i].time.difference(_frames[_liveIndex].time).inMinutes;
    if (diff.abs() < 3) return 'Now';
    final sign = diff < 0 ? '-' : '+';
    final a = diff.abs();
    if (a >= 60) {
      final h = a ~/ 60;
      final m = a % 60;
      return m == 0 ? '$sign${h}h' : '$sign${h}h ${m}m';
    }
    return '$sign${a}m';
  }

  double get _owmOpacity {
    switch (_layer) {
      case WeatherLayer.temperature:
        return 0.92;
      case WeatherLayer.wind:
        return 0.9;
      default:
        return 0.85;
    }
  }

  double get _owmSaturation => _layer == WeatherLayer.temperature ? 1.5 : 1.25;

  ColorFilter _saturation(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final ir = 1 - s;
    return ColorFilter.matrix(<double>[
      lr * ir + s,
      lg * ir,
      lb * ir,
      0,
      0,
      lr * ir,
      lg * ir + s,
      lb * ir,
      0,
      0,
      lr * ir,
      lg * ir,
      lb * ir + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  bool get _layerNeedsKey => _layer != WeatherLayer.radar && kOwmKey.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          _buildMap(),
          _buildTopLeft(),
          _buildSideButtons(),
          if (_layer == WeatherLayer.radar && _frames.isNotEmpty)
            _buildTimeline(),
          if (_loading) _statusPill(loading: true, text: 'Loading radar...'),
          if (!_loading && _error != null)
            _statusPill(loading: false, text: _error!, onTap: _load),
          if (!_loading &&
              _error == null &&
              _layer == WeatherLayer.radar &&
              _preparing)
            _statusPill(
              loading: true,
              text: 'Loading frames ${_mounted.length}/$_totalPast',
            ),
          if (_layerNeedsKey)
            _statusPill(
              loading: false,
              icon: Icons.key_rounded,
              text: 'Add OWM_KEY to enable ${_layer.label}',
            ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _nepal,
        initialZoom: _defaultZoom,
        minZoom: 3,
        maxZoom: 18,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) _onViewChanging();
        },
      ),
      children: [
        // 1. Base map
        TileLayer(
          key: ValueKey('base_${_base.name}'),
          urlTemplate: _base.baseUrl,
          userAgentPackageName: kUserAgent,
          maxNativeZoom: _base.baseNativeZoom,
          maxZoom: 18,
        ),
        if (_showOverlay && _layer == WeatherLayer.radar)
          for (int i = 0; i < _frames.length; i++)
            if (_shouldBuild(i))
              Opacity(
                key: ValueKey('frame_${_frames[i].urlTemplate}'),
                opacity: i == _index ? 0.85 : 0.01,
                child: TileLayer(
                  urlTemplate: _frames[i].urlTemplate,
                  userAgentPackageName: kUserAgent,
                  maxNativeZoom: _frames[i].maxNativeZoom,
                  maxZoom: 18,
                  tileDisplay: const TileDisplay.instantaneous(),
                  panBuffer: 0, // don't fetch extra rings for hidden frames
                  keepBuffer: 1,
                  evictErrorTileStrategy:
                      EvictErrorTileStrategy.notVisibleRespectMargin,
                ),
              ),

       
        if (_showOverlay && _layer != WeatherLayer.radar && kOwmKey.isNotEmpty)
          Opacity(
            key: ValueKey('owm_${_layer.name}'),
            opacity: _owmOpacity,
            child: ColorFiltered(
              // boost saturation so the colours stay vivid over the map
              colorFilter: _saturation(_owmSaturation),
              child: TileLayer(
                urlTemplate: 'https://tile.openweathermap.org/map/'
                    '${_layer.owmId}/{z}/{x}/{y}.png?appid=$kOwmKey',
                userAgentPackageName: kUserAgent,
                maxNativeZoom: kOwmMaxNativeZoom,
                maxZoom: 18,
                tileDisplay: const TileDisplay.instantaneous(),
              ),
            ),
          ),

        // 3. Labels on top
        if (_base.labelsUrl != null)
          TileLayer(
            key: ValueKey('labels_${_base.name}'),
            urlTemplate: _base.labelsUrl!,
            userAgentPackageName: kUserAgent,
            maxNativeZoom: _base.labelsNativeZoom,
            maxZoom: 18,
          ),

        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
                'Esri, HERE, Garmin, OpenStreetMap contributors'),
            TextSourceAttribution('RainViewer'),
            TextSourceAttribution('OpenWeatherMap'),
            TextSourceAttribution('Tomorrow.io'),
          ],
        ),
      ],
    );
  }

  // Layer chip + legend (top-left)
  Widget _buildTopLeft() {
    return Positioned(
      left: 14,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _openLayerSheet,
                child: _Glass(
                  radius: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_layer.icon,
                          color: const Color(0xFF6EA8FF), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _layer.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),
              if (_showOverlay && !_layerNeedsKey) ...[
                const SizedBox(height: 8),
                _Legend(layer: _layer),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideButtons() {
    return Positioned(
      right: 14,
      top: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              _RoundBtn(
                icon: _showOverlay
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                onTap: _toggleOverlay,
              ),
              const SizedBox(height: 8),
              _RoundBtn(icon: Icons.layers_rounded, onTap: _openLayerSheet),
              const SizedBox(height: 8),
              _RoundBtn(
                icon: Icons.my_location_rounded,
                onTap: () {
                  _onViewChanging();
                  _map.move(_nepal, _defaultZoom);
                },
              ),
              const SizedBox(height: 8),
              _RoundBtn(icon: Icons.add_rounded, onTap: () => _zoom(1)),
              const SizedBox(height: 8),
              _RoundBtn(icon: Icons.remove_rounded, onTap: () => _zoom(-1)),
              const SizedBox(height: 8),
              _RoundBtn(icon: Icons.refresh_rounded, onTap: _load),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill({
    required bool loading,
    required String text,
    IconData icon = Icons.refresh_rounded,
    VoidCallback? onTap,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Center(
            child: GestureDetector(
              onTap: onTap,
              child: _Glass(
                radius: 20,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final frame = _frames[_index];
    final isLive = _index == _liveIndex;
    final maxIdx = (_frames.length - 1).toDouble();

    return Positioned(
      left: 14,
      right: 14,
      bottom: widget.bottomInset,
      child: _Glass(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2A4A),
                  shape: BoxShape.circle,
                ),
                child: _ready
                    ? Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF6EA8FF),
                        size: 32,
                      )
                    : const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF6EA8FF),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _clock(frame.time),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        text: isLive
                            ? 'LIVE'
                            : (frame.isForecast ? 'FORECAST' : 'PAST'),
                        color: isLive
                            ? const Color(0xFFE5484D)
                            : (frame.isForecast
                                ? const Color(0xFF3D7BFF)
                                : Colors.grey.shade700),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 5,
                      activeTrackColor: const Color(0xFF4A72D8),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _index.toDouble().clamp(0, maxIdx),
                      min: 0,
                      max: maxIdx < 1 ? 1 : maxIdx,
                      divisions: _frames.length > 1 ? _frames.length - 1 : 1,
                      onChanged: (v) {
                        _stop();
                        setState(() => _index = v.round());
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_relative(0), style: _tickStyle),
                        Text(_relative(_index),
                            style: _tickStyle.copyWith(color: Colors.white)),
                        Text(_relative(_frames.length - 1), style: _tickStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _tickStyle = TextStyle(
      color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500);
}

class _Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const _Glass({
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF14161B).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(
        radius: 15,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 23),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Small colour legend (approximate palettes).
class _Legend extends StatelessWidget {
  final WeatherLayer layer;

  const _Legend({required this.layer});

  @override
  Widget build(BuildContext context) {
    late final List<Color> colors;
    late final String left;
    late final String right;

    switch (layer) {
      case WeatherLayer.radar:
        colors = const [
          Color(0xFF9FD6F5),
          Color(0xFF1F8AD1),
          Color(0xFF0B4F9C),
          Color(0xFFF3D000),
          Color(0xFFE8730C),
          Color(0xFFD62828),
        ];
        left = 'Light';
        right = 'Heavy';
        break;
      case WeatherLayer.temperature:
        colors = const [
          Color(0xFF821692),
          Color(0xFF208CEC),
          Color(0xFF23DDDD),
          Color(0xFFC2FF28),
          Color(0xFFFFF028),
          Color(0xFFFC8014),
        ];
        left = '-40°C';
        right = '+40°C';
        break;
      case WeatherLayer.clouds:
        colors = const [
          Color(0x00FFFFFF),
          Color(0x88FFFFFF),
          Color(0xFFFFFFFF),
        ];
        left = 'Clear';
        right = 'Overcast';
        break;
      case WeatherLayer.wind:
        colors = const [
          Color(0xFFCFE9FF),
          Color(0xFF5AB0FF),
          Color(0xFF7A5CFF),
          Color(0xFFB03AC9),
        ];
        left = 'Calm';
        right = 'Strong';
        break;
      case WeatherLayer.pressure:
        colors = const [
          Color(0xFF2C6BFF),
          Color(0xFF3FD0D4),
          Color(0xFFF7E04A),
          Color(0xFFE8503A),
        ];
        left = 'Low';
        right = 'High';
        break;
    }

    const style = TextStyle(color: Colors.white70, fontSize: 10.5);

    return _Glass(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: SizedBox(
        width: 130,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: colors),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(left, style: style), Text(right, style: style)],
            ),
          ],
        ),
      ),
    );
  }
}


class _LayerSheet extends StatelessWidget {
  final WeatherLayer selectedLayer;
  final BaseStyle selectedBase;
  final bool hasOwmKey;
  final ValueChanged<WeatherLayer> onLayer;
  final ValueChanged<BaseStyle> onBase;

  const _LayerSheet({
    required this.selectedLayer,
    required this.selectedBase,
    required this.hasOwmKey,
    required this.onLayer,
    required this.onBase,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF15171C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text('Weather layer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in WeatherLayer.values)
                  _Chip(
                    icon: l.icon,
                    label: l.label,
                    selected: l == selectedLayer,
                    locked: l != WeatherLayer.radar && !hasOwmKey,
                    onTap: () => onLayer(l),
                  ),
              ],
            ),
            if (!hasOwmKey)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Locked layers need an OpenWeatherMap key (OWM_KEY).',
                  style: TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              ),
            const SizedBox(height: 20),
            const Text('Map style',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in kBaseStyles)
                  _Chip(
                    icon: b.icon,
                    label: b.name,
                    selected: b.name == selectedBase.name,
                    onTap: () => onBase(b),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _Chip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3D7BFF).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF6EA8FF)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: locked ? Colors.white30 : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: locked ? Colors.white38 : Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_rounded, size: 13, color: Colors.white30),
            ],
          ],
        ),
      ),
    );
  }
}
