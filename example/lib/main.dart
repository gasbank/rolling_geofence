import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rolling_geofence/rolling_geofence.dart';
import 'package:sphere_uniform_geocoding/sphere_uniform_geocoding.dart';

@pragma('vm:entry-point')
void onGeofenceEvent(List<String> args) {
  if (kDebugMode) {
    print('onGeofenceEvent: $args');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _rollingGeofencePlugin = RollingGeofence();
  double _mapZoom = 14;
  double _geofenceRadius = 350;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _rollingGeofencePlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    _rollingGeofencePlugin.setOnLocationPermissionAllowed(() async {
      if (kDebugMode) {
        print('Location permission allowed');
      }

      await _rollingGeofencePlugin.requestBackgroundLocationPermission();
    });

    _rollingGeofencePlugin.setOnLocationPermissionDenied(() {
      if (kDebugMode) {
        print('Error: Location permission denied');
      }
    });

    _rollingGeofencePlugin.setOnLocationPermissionAlreadyAllowed(() async {
      if (kDebugMode) {
        print('Location permission already allowed');
      }

      await _rollingGeofencePlugin.requestBackgroundLocationPermission();
    });

    _rollingGeofencePlugin.setOnBackgroundLocationPermissionAllowed(() async {
      if (kDebugMode) {
        print('Background location permission allowed');
      }

      await _rollingGeofencePlugin.createGeofencingClient();
    });

    _rollingGeofencePlugin.setOnBackgroundLocationPermissionDenied(() {
      if (kDebugMode) {
        print('Error: Background location permission denied');
      }
    });

    _rollingGeofencePlugin
        .setOnBackgroundLocationPermissionAlreadyAllowed(() async {
      if (kDebugMode) {
        print('Background location permission already allowed');
      }

      await _rollingGeofencePlugin.createGeofencingClient();
    });

    _rollingGeofencePlugin.setOnSuccess((code) {
      if (kDebugMode) {
        print('Success: $code');
      }
    });

    _rollingGeofencePlugin.setOnError((code) {
      if (kDebugMode) {
        print('Error: $code');
      }
    });

    _rollingGeofencePlugin.setOnDidEnterRegionIos((name) {
      if (kDebugMode) {
        print('OnDidEnterRegionIos: $name');
      }
    });

    _rollingGeofencePlugin.setOnDidExitRegionIos((name) {
      if (kDebugMode) {
        print('OnDidExitRegionIos: $name');
      }
    });

    await _rollingGeofencePlugin.registerGeofence(
        name: 'home', latitude: 37.5217, longitude: 126.9344);
    await _rollingGeofencePlugin.registerGeofence(
        name: 'office1', latitude: 37.5275, longitude: 126.9165);
    await _rollingGeofencePlugin.registerGeofence(
        name: 'office2', latitude: 37.4955, longitude: 126.8437);
    await _rollingGeofencePlugin.registerGeofence(
        name: 'yoidostation', latitude: 37.5216, longitude: 126.9241);
    await _rollingGeofencePlugin.registerGeofence(
        name: 'penthouse', latitude: 37.5175, longitude: 126.9319);

    //await _rollingGeofencePlugin.createGeofencingClient();

    //await _requestLocationPermission();

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _requestLocationPermission() async {
    await _rollingGeofencePlugin.requestLocationPermission();
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
        body: ListView(
          children: [
            Text('Running on: $_platformVersion\n'),
            TextButton(
                onPressed: _requestLocationPermission,
                child: const Text('권한 요청!')),
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
                        point:
                            LatLng(centerLat / pi * 180, centerLng / pi * 180),
                        radius: _geofenceRadius,
                        useRadiusInMeter: true,
                        borderStrokeWidth: 2,
                        borderColor: Colors.deepOrange,
                        color: Colors.transparent),
                    for (final (neighborLat, neighborLng)
                        in neighborLatLngList) ...[
                      CircleMarker(
                          point: LatLng(
                              neighborLat / pi * 180, neighborLng / pi * 180),
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
      ),
    );
  }
}
