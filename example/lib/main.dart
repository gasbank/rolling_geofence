import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rolling_geofence/rolling_geofence.dart';

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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              TextButton(
                  onPressed: _requestLocationPermission,
                  child: const Text('권한 요청!')),
            ],
          ),
        ),
      ),
    );
  }
}
