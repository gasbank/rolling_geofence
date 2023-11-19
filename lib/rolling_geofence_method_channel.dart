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
        case "onLocationPermissionAllowed":
          if (onLocationPermissionAllowed != null) {
            onLocationPermissionAllowed!();
          }
          break;
        case "onLocationPermissionDenied":
          if (onLocationPermissionDenied != null) {
            onLocationPermissionDenied!();
          }
          break;
        case "onBackgroundLocationPermissionAllowed":
          if (onBackgroundLocationPermissionAllowed != null) {
            onBackgroundLocationPermissionAllowed!();
          }
          break;
        case "onBackgroundLocationPermissionDenied":
          if (onBackgroundLocationPermissionDenied != null) {
            onBackgroundLocationPermissionDenied!();
          }
          break;
        case "onSuccess":
          if (onSuccess != null) {
            onSuccess!(call.arguments['code']);
          }
          break;
        case "onError":
          if (onError != null) {
            onError!(call.arguments['code']);
          }
          break;
      }

      return SynchronousFuture(null);
    });
  }

  @override
  Future<String?> requestLocationPermission() async {
    final ret = await methodChannel.invokeMethod<String>('requestLocationPermission');
    return ret;
  }

  @override
  Future<String?> requestBackgroundLocationPermission() async {
    final ret = await methodChannel.invokeMethod<String>('requestBackgroundLocationPermission');
    return ret;
  }

  @override
  Future<String?> startLocationRequest() async {
    final ret = await methodChannel.invokeMethod<String>('startLocationRequest');
    return ret;
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> registerGeofence({required String name, required double latitude, required double longitude}) async {
    final ret = await methodChannel.invokeMethod<String>('registerGeofence', <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    });
    return ret;
  }

  @override
  Future<String?> createGeofencingClient() async {
    final ret = await methodChannel.invokeMethod<String>('createGeofencingClient');
    return ret;
  }
}
