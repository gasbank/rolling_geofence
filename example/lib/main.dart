import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rolling_geofence/rolling_geofence.dart';
import 'package:sphere_uniform_geocoding/sphere_uniform_geocoding.dart';

@pragma('vm:entry-point')
void onGeofenceEvent(List<String> args) async {
  if (kDebugMode) {
    print('onGeofenceEvent: $args');
  }

  WidgetsFlutterBinding.ensureInitialized();

  final rollingGeofencePlugin = RollingGeofence();
  await rollingGeofencePlugin.createGeofencingClient();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _platformVersion = 'Unknown';
  bool? _fgPermission;
  bool? _bgPermission;
  bool? _showFgRationale;
  bool? _showBgRationale;
  String? _isIgnoringBatteryOptimizations;
  final _plugin = RollingGeofence();
  double _mapZoom = 14;
  double _geofenceRadius = 350;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initPlatformState();
    _updatePermissionStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePermissionStates();
    }
  }

  void _updatePermissionStates() {
    _plugin
        .checkFgPermission()
        .then((value) => setState(() => _fgPermission = value));
    _plugin
        .checkBgPermission()
        .then((value) => setState(() => _bgPermission = value));
    _plugin
        .shouldShowFgRationale()
        .then((value) => setState(() => _showFgRationale = value));
    _plugin
        .shouldShowBgRationale()
        .then((value) => setState(() => _showBgRationale = value));
    _plugin.isIgnoringBatteryOptimizations().then(
        (value) => setState(() => _isIgnoringBatteryOptimizations = value));
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _plugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _plugin.setOnDidEnterRegionIos((name) {
      if (kDebugMode) {
        print('OnDidEnterRegionIos: $name');
      }
    });

    _plugin.setOnDidExitRegionIos((name) {
      if (kDebugMode) {
        print('OnDidExitRegionIos: $name');
      }
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _checkLocationPermission(BuildContext context) async {
    String? checkPermissionResult;
    try {
      checkPermissionResult = await _plugin.checkLocationPermission();
    } on PlatformException catch (e) {
      checkPermissionResult = e.code;
    }

    final resultMsg =
        'Check location permission result: $checkPermissionResult';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultMsg),
      ));
    }

    if (kDebugMode) {
      print(resultMsg);
    }
  }

  Future<void> _requestForegroundPermission(BuildContext context) async {
    String? foregroundResult;

    try {
      foregroundResult = await _plugin.requestLocationPermission();
    } on PlatformException catch (e) {
      foregroundResult = e.code;
    }

    final resultMsg =
        'Request foreground location permission result: $foregroundResult';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultMsg),
      ));
    }

    if (kDebugMode) {
      print(resultMsg);
    }
  }

  Future<void> _requestBackgroundPermission(BuildContext context) async {
    String? backgroundResult;
    try {
      backgroundResult = await _plugin.requestBackgroundLocationPermission();
    } on PlatformException catch (e) {
      backgroundResult = e.code;
    }

    final resultMsg =
        'Request background location permission result: $backgroundResult';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultMsg),
      ));
    }

    if (kDebugMode) {
      print(resultMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    const subdivisionCount = 14654;
    const userPosLatDeg = 37.5275;
    const userPosLngDeg = 126.9165;
    final segIndex = calculateSegmentIndexFromLatLng(
        subdivisionCount, userPosLatDeg / 180 * pi, userPosLngDeg / 180 * pi);
    final (centerLat, centerLng) =
        calculateSegmentCenter(subdivisionCount, segIndex);
    final neighborIndices =
        getNeighborsOfSegmentIndex(subdivisionCount, segIndex);
    final neighborLatLngList = neighborIndices.map((e) {
      return calculateSegmentCenter(subdivisionCount, e);
    });

    final centerCorners =
        calculateSegmentCornersInLatLng(subdivisionCount, segIndex).map((e) {
      final (lat, lng) = e;
      return LatLng(lat / pi * 180, lng / pi * 180);
    }).toList();

    final neighborCorners = neighborIndices.map((e) {
      final corners = calculateSegmentCornersInLatLng(subdivisionCount, e);
      return corners.map((e) {
        final (lat, lng) = e;
        return LatLng(lat / pi * 180, lng / pi * 180);
      }).toList();
    });

    return MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return SafeArea(
            child: ListView(
              children: [
                Text('Running on: $_platformVersion'),
                Text('Foreground Permission: $_fgPermission'),
                Text('Background Permission: $_bgPermission'),
                Text('Show Foreground Rationale: $_showFgRationale'),
                Text('Show Background Rationale: $_showBgRationale'),
                Text(
                    'Is Ignoring Battery Optimizations: $_isIgnoringBatteryOptimizations'),
                TextButton(
                    onPressed: () => _checkLocationPermission(context),
                    child: const Text('현재 권한 상태 체크만 하기')),
                TextButton(
                    onPressed: () => _requestForegroundPermission(context),
                    child: const Text('포그라운드 권한 요청')),
                TextButton(
                    onPressed: () => _requestBackgroundPermission(context),
                    child: const Text('백그라운드 권한 요청')),
                TextButton(
                    onPressed: () => _createGeofencingClient(context),
                    child: const Text('Geofencing Client 생성')),
                TextButton(
                    onPressed: () async {
                      final result = await _plugin.startSingleLocationRequest();
                      final resultMsg =
                          "Single Location Request Result: $result";
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(resultMsg),
                        ));
                      }
                      if (kDebugMode) {
                        print(resultMsg);
                      }
                    },
                    child: const Text('현재 좌표 조회')),
                TextButton(
                    onPressed: () async {
                      await _plugin.openApplicationDetailsSettings();
                    },
                    child: const Text('앱 설정 열기 (Android)')),
                TextButton(
                    onPressed: () async {
                      await _plugin.requestBatteryOptimizationPermission();
                    },
                    child: const Text('배터리 제한 없이 사용 권한 요청')),
                SizedBox(
                  width: 500,
                  height: 500,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          LatLng(centerLat / pi * 180, centerLng / pi * 180),
                      initialZoom: _mapZoom,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'top.plusalpha.rolling_geofence',
                      ),
                      PolygonLayer(polygons: [
                        Polygon(
                          points: centerCorners,
                          borderColor: Colors.black,
                          borderStrokeWidth: 1,
                        ),
                        for (final neighborCorner in neighborCorners) ...[
                          Polygon(
                            points: neighborCorner,
                            borderColor: Colors.black,
                            borderStrokeWidth: 1,
                          ),
                        ],
                      ]),
                      CircleLayer(circles: [
                        const CircleMarker(
                            point: LatLng(userPosLatDeg, userPosLngDeg),
                            radius: 20,
                            useRadiusInMeter: true,
                            color: Colors.red),
                        CircleMarker(
                            point: LatLng(
                                centerLat / pi * 180, centerLng / pi * 180),
                            radius: _geofenceRadius,
                            useRadiusInMeter: true,
                            borderStrokeWidth: 2,
                            borderColor: Colors.deepOrange,
                            color: Colors.transparent),
                        for (final (neighborLat, neighborLng)
                            in neighborLatLngList) ...[
                          CircleMarker(
                              point: LatLng(neighborLat / pi * 180,
                                  neighborLng / pi * 180),
                              radius: _geofenceRadius,
                              useRadiusInMeter: true,
                              borderStrokeWidth: 2,
                              borderColor: Colors.cyanAccent,
                              color: Colors.transparent)
                        ]
                      ])
                    ],
                  ),
                ),
                Text('Map Zoom: $_mapZoom'),
                Slider(
                  value: _mapZoom,
                  onChanged: (double value) {
                    setState(() {
                      _mapZoom = value;
                      _mapController.move(_mapController.camera.center, value);
                    });
                  },
                  min: 1,
                  max: 20,
                ),
                Text('Geofence Radius: $_geofenceRadius'),
                Slider(
                  value: _geofenceRadius,
                  onChanged: (double value) {
                    setState(() {
                      _geofenceRadius = value;
                    });
                  },
                  min: 200,
                  max: 500,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _createGeofencingClient(BuildContext context) async {
    String? result;
    try {
      await _plugin.registerGeofence(
          name: 'home', latitude: 37.5217, longitude: 126.9344);
      await _plugin.registerGeofence(
          name: 'office1', latitude: 37.5275, longitude: 126.9165);
      await _plugin.registerGeofence(
          name: 'office2', latitude: 37.4955, longitude: 126.8437);
      await _plugin.registerGeofence(
          name: 'yoidostation', latitude: 37.5216, longitude: 126.9241);
      await _plugin.registerGeofence(
          name: 'penthouse', latitude: 37.5175, longitude: 126.9319);

      result = await _plugin.createGeofencingClient();
    } on PlatformException catch (e) {
      result = e.code;
    }

    final resultMsg = 'Create Geofencing Client result: $result';

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resultMsg),
      ));
    }

    if (kDebugMode) {
      print(resultMsg);
    }
  }
}
