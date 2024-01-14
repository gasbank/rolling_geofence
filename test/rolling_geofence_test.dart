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
  Function? onLocationPermissionAllowed;

  @override
  Function? onLocationPermissionDenied;

  @override
  Function? onBackgroundLocationPermissionAllowed;

  @override
  Function? onBackgroundLocationPermissionDenied;

  @override
  Function(int p1)? onError;

  @override
  Function(int p1)? onSuccess;

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
  void setOnError(Function(int p1) callback) {
    // TODO: implement setOnError
  }

  @override
  void setOnLocationPermissionAllowed(Function callback) {
    // TODO: implement setOnLocationPermissionAllowed
  }

  @override
  void setOnLocationPermissionDenied(Function callback) {
    // TODO: implement setOnLocationPermissionDenied
  }

  @override
  void setOnSuccess(Function(int p1) callback) {
    // TODO: implement setOnSuccess
  }

  @override
  void setOnBackgroundLocationPermissionAllowed(Function callback) {
    // TODO: implement setOnBackgroundLocationPermissionAllowed
  }

  @override
  void setOnBackgroundLocationPermissionDenied(Function callback) {
    // TODO: implement setOnBackgroundLocationPermissionDenied
  }

  @override
  Future<String?> startLocationRequest() {
    // TODO: implement startLocationRequest
    throw UnimplementedError();
  }

  @override
  Function? onBackgroundLocationPermissionAlreadyAllowed;

  @override
  Function? onLocationPermissionAlreadyAllowed;

  @override
  void setOnBackgroundLocationPermissionAlreadyAllowed(Function callback) {
    // TODO: implement setOnBackgroundLocationPermissionAlreadyAllowed
  }

  @override
  void setOnLocationPermissionAlreadyAllowed(Function callback) {
    // TODO: implement setOnLocationPermissionAlreadyAllowed
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
