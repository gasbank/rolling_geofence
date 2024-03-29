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
  Future<bool?> checkFgPermission() async {
    return await methodChannel.invokeMethod<bool>('checkFgPermission');
  }

  @override
  Future<bool?> checkBgPermission() async {
    return await methodChannel.invokeMethod<bool>('checkBgPermission');
  }

  @override
  Future<bool?> shouldShowFgRationale() async {
    return await methodChannel.invokeMethod<bool>('shouldShowFgRationale');
  }

  @override
  Future<bool?> shouldShowBgRationale() async {
    return await methodChannel.invokeMethod<bool>('shouldShowBgRationale');
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

    final result = switch (ret.runtimeType) {
      const (List<Object?>) => List<double>.from(ret),
      _ => List<double>.from([]),
    };

    return result;
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
    final ret = await methodChannel
        .invokeMethod<String>('requestBatteryOptimizationPermission');
    return ret;
  }

  @override
  Future<String?> isIgnoringBatteryOptimizations() async {
    final ret = await methodChannel
        .invokeMethod<String>('isIgnoringBatteryOptimizations');
    return ret;
  }

  @override
  Future<bool?> checkBackgroundLocationRationale() async {
    final ret = await methodChannel
        .invokeMethod<bool>('checkBackgroundLocationRationale');
    return ret;
  }

  @override
  Future<void> openApplicationDetailsSettings() async {
    final ret = await methodChannel
        .invokeMethod<void>('openApplicationDetailsSettings');
    return ret;
  }
}
