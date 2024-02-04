import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rolling_geofence_platform_interface.dart';

/// An implementation of [RollingGeofencePlatform] that uses method channels.
class MethodChannelRollingGeofence extends RollingGeofencePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rolling_geofence');

  MethodChannelRollingGeofence() {
    methodChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case "onDidEnterRegionIos":
          if (onDidEnterRegionIos != null) {
            onDidEnterRegionIos!(call.arguments["name"]);
          }
          break;
        case "onDidExitRegionIos":
          if (onDidExitRegionIos != null) {
            onDidExitRegionIos!(call.arguments["name"]);
          }
          break;
      }

      return SynchronousFuture(null);
    });
  }

  @override
  Future<String?> requestLocationSetting() async {
    final ret =
        await methodChannel.invokeMethod<String>('requestLocationSetting');
    return ret;
  }

  @override
  Future<String?> requestLocationPermission() async {
    try {
      final ret =
          await methodChannel.invokeMethod<String>('requestLocationPermission');

      return ret;
    } on PlatformException catch (e) {
      return e.code;
    }
  }

  @override
  Future<String?> requestBackgroundLocationPermission() async {
    final ret = await methodChannel
        .invokeMethod<String>('requestBackgroundLocationPermission');
    return ret;
  }

  @override
  Future<String?> startLocationRequest() async {
    final ret =
        await methodChannel.invokeMethod<String>('startLocationRequest');
    return ret;
  }

  @override
  Future<List<double>> startSingleLocationRequest() async {
    final ret = await methodChannel.invokeMethod('startSingleLocationRequest');
    return List<double>.from(ret ?? []);
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> registerGeofence(
      {required String name,
      required double latitude,
      required double longitude}) async {
    final ret = await methodChannel
        .invokeMethod<String>('registerGeofence', <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    });
    return ret;
  }

  @override
  Future<String?> updateGeofence() async {
    await methodChannel.invokeMethod('updateGeofence');
  }

  @override
  Future<String?> clearGeofence() async {
    await methodChannel.invokeMethod('clearGeofence');
  }

  @override
  Future<String?> createGeofencingClient() async {
    final ret =
        await methodChannel.invokeMethod<String>('createGeofencingClient');
    return ret;
  }

  @override
  Future<String?> checkLocationPermission() async {
    final ret =
        await methodChannel.invokeMethod<String>('checkLocationPermission');
    return ret;
  }

  @override
  Future<String?> requestBatteryOptimizationPermission() async {
    final ret = await methodChannel.invokeMethod<String>('requestBatteryOptimizationPermission');
    return ret;
  }
}
