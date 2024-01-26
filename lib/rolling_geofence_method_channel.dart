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
        // 위치 권한을 이번에 사용자가 허용했을 때 호출
        case "onLocationPermissionAllowed":
          if (onLocationPermissionAllowed != null) {
            onLocationPermissionAllowed!();
          }
          break;
        // 위치 권한을 이번에 사용자가 거절했을 때 호출
        case "onLocationPermissionDenied":
          if (onLocationPermissionDenied != null) {
            onLocationPermissionDenied!();
          }
          break;
        // 위치 권한이 이미 허용된 상태일 때 호출
        case "onLocationPermissionAlreadyAllowed":
          if (onLocationPermissionAlreadyAllowed != null) {
            onLocationPermissionAlreadyAllowed!();
          }
          break;
        // 백그라운드 위치 권한을 이번에 사용자가 허용했을 때 호출
        case "onBackgroundLocationPermissionAllowed":
          if (onBackgroundLocationPermissionAllowed != null) {
            onBackgroundLocationPermissionAllowed!();
          }
          break;
        // 백그라운드 위치 권한을 이번에 사용자가 거절했을 때 호출
        case "onBackgroundLocationPermissionDenied":
          if (onBackgroundLocationPermissionDenied != null) {
            onBackgroundLocationPermissionDenied!();
          }
          break;
        // 백그라운드 위치 권한이 이미 허용된 상태일 때 호출
        case "onBackgroundLocationPermissionAlreadyAllowed":
          if (onBackgroundLocationPermissionAlreadyAllowed != null) {
            onBackgroundLocationPermissionAlreadyAllowed!();
          }
          break;
        // 기타 성공 코드 알림
        case "onSuccess":
          if (onSuccess != null) {
            onSuccess!(call.arguments['code']);
          }
          break;
        // 기타 실패 코드 알림
        case "onError":
          if (onError != null) {
            onError!(call.arguments['code']);
          }
          break;
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
}
