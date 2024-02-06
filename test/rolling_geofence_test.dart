import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_geofence/rolling_geofence.dart';
import 'package:rolling_geofence/rolling_geofence_platform_interface.dart';
import 'package:rolling_geofence/rolling_geofence_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRollingGeofencePlatform
    with MockPlatformInterfaceMixin
    implements RollingGeofencePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> createGeofencingClient() {
    // TODO: implement createGeofencingClient
    throw UnimplementedError();
  }

  @override
  Future<String?> registerGeofence(
      {required String name,
      required double latitude,
      required double longitude}) {
    // TODO: implement registerGeofence
    throw UnimplementedError();
  }

  @override
  Future<String?> requestBackgroundLocationPermission() {
    // TODO: implement requestBackgroundLocationPermission
    throw UnimplementedError();
  }

  @override
  Future<String?> requestLocationPermission() {
    // TODO: implement requestLocationPermission
    throw UnimplementedError();
  }

  @override
  Future<String?> startLocationRequest() {
    // TODO: implement startLocationRequest
    throw UnimplementedError();
  }

  @override
  Function(String p1)? onDidEnterRegionIos;

  @override
  Function(String p1)? onDidExitRegionIos;

  @override
  Future<String?> clearGeofence() {
    // TODO: implement clearGeofence
    throw UnimplementedError();
  }

  @override
  void setOnDidEnterRegionIos(Function(String p1) callback) {
    // TODO: implement setOnDidEnterRegionIos
  }

  @override
  void setOnDidExitRegionIos(Function(String p1) callback) {
    // TODO: implement setOnDidExitRegionIos
  }

  @override
  Future<String?> updateGeofence() {
    // TODO: implement updateGeofence
    throw UnimplementedError();
  }

  @override
  Future<List<double>> startSingleLocationRequest() {
    // TODO: implement startSingleLocationRequest
    throw UnimplementedError();
  }

  @override
  Future<String?> checkLocationPermission() {
    // TODO: implement checkLocationPermission
    throw UnimplementedError();
  }

  @override
  Future<String?> requestLocationSetting() {
    // TODO: implement requestLocationSetting
    throw UnimplementedError();
  }

  @override
  Future<bool?> checkBackgroundLocationRationale() {
    // TODO: implement checkBackgroundLocationRationale
    throw UnimplementedError();
  }

  @override
  Future<String?> requestBatteryOptimizationPermission() {
    // TODO: implement requestBatteryOptimizationPermission
    throw UnimplementedError();
  }

  @override
  Future<bool?> checkBgPermission() {
    // TODO: implement checkBgPermission
    throw UnimplementedError();
  }

  @override
  Future<bool?> checkFgPermission() {
    // TODO: implement checkFgPermission
    throw UnimplementedError();
  }

  @override
  Future<bool?> shouldShowBgRationale() {
    // TODO: implement shouldShowBgRationale
    throw UnimplementedError();
  }

  @override
  Future<bool?> shouldShowFgRationale() {
    // TODO: implement shouldShowFgRationale
    throw UnimplementedError();
  }
}

void main() {
  final RollingGeofencePlatform initialPlatform =
      RollingGeofencePlatform.instance;

  test('$MethodChannelRollingGeofence is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRollingGeofence>());
  });

  test('getPlatformVersion', () async {
    RollingGeofence rollingGeofencePlugin = RollingGeofence();
    MockRollingGeofencePlatform fakePlatform = MockRollingGeofencePlatform();
    RollingGeofencePlatform.instance = fakePlatform;

    expect(await rollingGeofencePlugin.getPlatformVersion(), '42');
  });
}
