import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum WeatherLayerType {
  radar(
    'Rain Radar',
    Icons.water_drop,
  ),

  temperature(
    'Temperature',
    Icons.thermostat,
  ),

  clouds(
    'Clouds',
    Icons.cloud,
  ),

  wind(
    'Wind',
    Icons.air,
  ),

  pressure(
    'Pressure',
    Icons.speed,
  ),

  none(
    'None',
    Icons.layers_clear,
  );

  final String label;
  final IconData icon;

  const WeatherLayerType(
    this.label,
    this.icon,
  );
}

class RadarFrame {
  final int time;
  final String path;

  const RadarFrame({
    required this.time,
    required this.path,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  static const String _openWeatherApiKey =
      '915e20e5765c5a2faf877bd8305c5c57';

  static const LatLng _nepalCenter = LatLng(
    28.3949,
    84.1240,
  );
  static const double _defaultZoom = 6.3;

  static const double _minZoom = 3.0;

  static const double _maxZoom = 18.0;


  WeatherLayerType _selectedLayer =
      WeatherLayerType.radar;

  List<RadarFrame> _radarFrames = [];

  int _currentRadarIndex = 0;
  bool _loadingRadar = true;
  bool _isPlaying = false;
  Timer? _radarTimer;
  String _radarHost = '';
  @override
  void initState() {
    super.initState();

    _loadRadarData();
  }

  @override
  void dispose() {

    _radarTimer?.cancel();

    super.dispose();
  }

  Future<void> _loadRadarData() async {

    try {

      setState(() {
        _loadingRadar = true;
      });


      final response = await http.get(
        Uri.parse(
          'https://api.rainviewer.com/public/weather-maps.json',
        ),
      );


      if (response.statusCode != 200) {

        throw Exception(
          'Radar API returned ${response.statusCode}',
        );
      }


      final data = jsonDecode(response.body);


      final String host = data['host'];


      final List radarPast =
          data['radar']['past'] ?? [];


      final List<RadarFrame> frames = [];


      for (final item in radarPast) {

        final time = item['time'];

        final path = item['path'];

        if (time is int && path is String) {

          frames.add(
            RadarFrame(
              time: time,
              path: path,
            ),
          );
        }
      }


      if (!mounted) return;


      setState(() {

        _radarHost = host;

        _radarFrames = frames;

        _currentRadarIndex =
            frames.isEmpty ? 0 : frames.length - 1;

        _loadingRadar = false;
      });

    } catch (e) {

      debugPrint(
        'RainViewer error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loadingRadar = false;
      });
    }
  }

  String? get _radarTileUrl {

    if (_radarFrames.isEmpty ||
        _radarHost.isEmpty) {
      return null;
    }


    final frame =
        _radarFrames[_currentRadarIndex];


    

    return '$_radarHost'
        '${frame.path}'
        '/512/{z}/{x}/{y}/2/1_1.png';
  }

  String get _openWeatherTileUrl {

    String layer;

    switch (_selectedLayer) {

      case WeatherLayerType.temperature:
        layer = 'temp_new';
        break;

      case WeatherLayerType.clouds:
        layer = 'clouds_new';
        break;

      case WeatherLayerType.wind:
        layer = 'wind_new';
        break;

      case WeatherLayerType.pressure:
        layer = 'pressure_new';
        break;

      default:
        layer = 'clouds_new';
    }


    return 'https://tile.openweathermap.org/map/'
        '$layer/{z}/{x}/{y}.png'
        '?appid=$_openWeatherApiKey';
  }


  void _zoomIn() {

    final zoom =
        _mapController.camera.zoom;


    if (zoom < _maxZoom) {

      _mapController.move(
        _mapController.camera.center,
        zoom + 1,
      );
    }
  }

  void _zoomOut() {

    final zoom =
        _mapController.camera.zoom;


    if (zoom > _minZoom) {

      _mapController.move(
        _mapController.camera.center,
        zoom - 1,
      );
    }
  }

  void _goToNepal() {

    _mapController.move(
      _nepalCenter,
      _defaultZoom,
    );
  }


  void _changeLayer(
    WeatherLayerType layer,
  ) {

    // Stop animation when switching away
    // from radar.

    if (layer != WeatherLayerType.radar) {

      _stopRadarAnimation();
    }


    setState(() {

      _selectedLayer = layer;
    });
  }


  void _startRadarAnimation() {

    if (_radarFrames.length < 2) {
      return;
    }


    _radarTimer?.cancel();


    setState(() {

      _isPlaying = true;

      _selectedLayer =
          WeatherLayerType.radar;
    });


    _radarTimer = Timer.periodic(
      const Duration(
        milliseconds: 500,
      ),
      (timer) {

        if (!mounted) {

          timer.cancel();

          return;
        }


        setState(() {

          _currentRadarIndex++;

          if (_currentRadarIndex >=
              _radarFrames.length) {

            _currentRadarIndex = 0;
          }
        });
      },
    );
  }

  void _stopRadarAnimation() {

    _radarTimer?.cancel();

    _radarTimer = null;


    if (mounted) {

      setState(() {

        _isPlaying = false;
      });
    }
  }

  void _toggleRadarAnimation() {

    if (_isPlaying) {

      _stopRadarAnimation();

    } else {

      _startRadarAnimation();
    }
  }


  void _showLayerMenu() {

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (context) {

        return _LayerSheet(
          selectedLayer: _selectedLayer,

          onSelected: (layer) {

            _changeLayer(layer);

            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: Stack(

        children: [
          FlutterMap(

            mapController:
                _mapController,

            options: const MapOptions(

              initialCenter:
                  _nepalCenter,

              initialZoom:
                  _defaultZoom,

              minZoom:
                  _minZoom,

              maxZoom:
                  _maxZoom,
            ),

            children: [
              TileLayer(

                urlTemplate:
                    'https://server.arcgisonline.com/'
                    'ArcGIS/rest/services/'
                    'World_Imagery/'
                    'MapServer/tile/{z}/{y}/{x}',

                userAgentPackageName:
                    'com.example.weather_app_3d',

                maxZoom:
                    _maxZoom,

                maxNativeZoom:
                    18,
              ),

              if (
                _selectedLayer ==
                    WeatherLayerType.radar
              )

                if (_radarTileUrl != null)

                  Opacity(

                    opacity: 0.72,

                    child: TileLayer(

                      key: ValueKey(
                        '$_currentRadarIndex'
                        '_radar',
                      ),

                      urlTemplate:
                          _radarTileUrl!,

                      userAgentPackageName:
                          'com.example.weather_app_3d',

                      maxZoom: 7,

                      maxNativeZoom: 7,

                      tileSize: 512,
                    ),
                  ),

              if (
                _selectedLayer ==
                    WeatherLayerType.temperature ||
                _selectedLayer ==
                    WeatherLayerType.clouds ||
                _selectedLayer ==
                    WeatherLayerType.wind ||
                _selectedLayer ==
                    WeatherLayerType.pressure
              )

                Opacity(

                  opacity: 0.55,

                  child: TileLayer(

                    urlTemplate:
                        _openWeatherTileUrl,

                    userAgentPackageName:
                        'com.example.weather_app_3d',

                    maxZoom:
                        9,

                    maxNativeZoom:
                        9,
                  ),
                ),

              TileLayer(

                urlTemplate:
                    'https://server.arcgisonline.com/'
                    'ArcGIS/rest/services/'
                    'Reference/'
                    'World_Boundaries_and_Places/'
                    'MapServer/tile/{z}/{y}/{x}',

                userAgentPackageName:
                    'com.example.weather_app_3d',

                maxZoom:
                    _maxZoom,

                maxNativeZoom:
                    16,
              ),
              const RichAttributionWidget(

                alignment:
                    AttributionAlignment.bottomLeft,

                attributions: [

                  TextSourceAttribution(
                    'Esri, Maxar, Earthstar Geographics',
                  ),

                  TextSourceAttribution(
                    'OpenWeatherMap',
                  ),

                  TextSourceAttribution(
                    'RainViewer',
                  ),
                ],
              ),
            ],
          ),
          if (_loadingRadar)

            Positioned(
              top: 60,
              left: 0,
              right: 0,

              child: Center(

                child: Container(

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        Colors.black.withOpacity(
                      0.70,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      SizedBox(
                        width: 15,
                        height: 15,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(width: 8),

                      Text(
                        'Loading radar...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(

            right: 16,

            // Keep this above your own bottom navigation.
            bottom: 110,

            child: Column(

              children: [
                _MapButton(
                  icon: Icons.add,
                  onTap: _zoomIn,
                ),

                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  onTap: _zoomOut,
                ),

                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _goToNepal,
                ),

                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.layers,
                  active:
                      _selectedLayer !=
                      WeatherLayerType.none,

                  onTap: _showLayerMenu,
                ),
              ],
            ),
          ),

          if (
            _selectedLayer ==
                WeatherLayerType.radar &&
            _radarFrames.length > 1
          )

            Positioned(

              left: 18,

              // Above your bottom navigation.
              bottom: 110,

              child: GestureDetector(

                onTap:
                    _toggleRadarAnimation,

                child: Container(

                  width: 52,
                  height: 52,

                  decoration:
                      BoxDecoration(

                    color:
                        Colors.black.withOpacity(
                      0.78,
                    ),

                    shape:
                        BoxShape.circle,

                    boxShadow: [

                      BoxShadow(
                        color:
                            Colors.black.withOpacity(
                          0.25,
                        ),

                        blurRadius: 10,

                        offset:
                            const Offset(
                          0,
                          3,
                        ),
                      ),
                    ],
                  ),

                  child: Icon(

                    _isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,

                    color:
                        Colors.white,

                    size: 27,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class _MapButton extends StatelessWidget {

  final IconData icon;

  final VoidCallback onTap;

  final bool active;


  const _MapButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        width: 46,
        height: 46,

        decoration: BoxDecoration(

          color: active
              ? Colors.black
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          boxShadow: [

            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.22,
              ),

              blurRadius: 9,

              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child: Icon(

          icon,

          color: active
              ? Colors.white
              : Colors.black87,

          size: 23,
        ),
      ),
    );
  }
}


class _LayerSheet extends StatelessWidget {

  final WeatherLayerType selectedLayer;

  final Function(
    WeatherLayerType,
  ) onSelected;


  const _LayerSheet({
    required this.selectedLayer,
    required this.onSelected,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return Container(

      margin:
          const EdgeInsets.all(12),

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color:
            const Color(0xFF151515),

        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),

      child: Column(

        mainAxisSize:
            MainAxisSize.min,

        children: [


          Container(

            width: 40,
            height: 4,

            margin:
                const EdgeInsets.only(
              bottom: 18,
            ),

            decoration:
                BoxDecoration(

              color:
                  Colors.white24,

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),


          const Align(

            alignment:
                Alignment.centerLeft,

            child: Text(
              'Weather Layers',

              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),


          const SizedBox(
            height: 14,
          ),


          ...WeatherLayerType.values.map(

            (layer) {

              final selected =
                  selectedLayer == layer;


              return GestureDetector(

                onTap: () {
                  onSelected(layer);
                },


                child: Container(

                  margin:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),

                  decoration:
                      BoxDecoration(

                    color: selected
                        ? Colors.white
                            .withOpacity(0.13)
                        : Colors.white
                            .withOpacity(0.05),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    border: Border.all(

                      color: selected
                          ? Colors.white
                              .withOpacity(0.35)
                          : Colors.transparent,
                    ),
                  ),


                  child: Row(

                    children: [

                      Icon(
                        layer.icon,

                        color:
                            Colors.white,

                        size: 22,
                      ),


                      const SizedBox(
                        width: 14,
                      ),


                      Text(

                        layer.label,

                        style:
                            const TextStyle(

                          color:
                              Colors.white,

                          fontSize:
                              15,

                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),


                      const Spacer(),


                      if (selected)

                        const Icon(
                          Icons.check_circle,

                          color:
                              Colors.white,

                          size: 21,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}