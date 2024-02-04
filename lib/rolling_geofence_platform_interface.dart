import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rolling_geofence_method_channel.dart';

abstract class RollingGeofencePlatform extends PlatformInterface {
  /// Constructs a RollingGeofencePlatform.
  RollingGeofencePlatform() : super(token: _token);

  static final Object _token = Object();

  static RollingGeofencePlatform _instance = MethodChannelRollingGeofence();

  /// The default instance of [RollingGeofencePlatform] to use.
  ///
  /// Defaults to [MethodChannelRollingGeofence].
  static RollingGeofencePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RollingGeofencePlatform] when
  /// they register themselves.
  static set instance(RollingGeofencePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Function(String)? onDidEnterRegionIos;
  Function(String)? onDidExitRegionIos;

  Future<String?> requestLocationSetting() {
    throw UnimplementedError(
        'requestLocationSetting() has not been implemented.');
  }

  Future<String?> requestLocationPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<String?> requestBackgroundLocationPermission() {
    throw UnimplementedError(
        'requestBackgroundLocationPermission() has not been implemented.');
  }

  Future<String?> startLocationRequest() {
    throw UnimplementedError(
        'startLocationRequest() has not been implemented.');
  }

  Future<List<double>> startSingleLocationRequest() {
    throw UnimplementedError(
        'startSingleLocationRequest() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<String?> registerGeofence(
      {required String name,
      required double latitude,
      required double longitude}) {
    throw UnimplementedError('registerGeofence() has not been implemented.');
  }

  Future<String?> updateGeofence() {
    throw UnimplementedError('updateGeofence() has not been implemented.');
  }

  Future<String?> clearGeofence() async {
    throw UnimplementedError('updateGeofence() has not been implemented.');
  }

  Future<String?> createGeofencingClient() {
    throw UnimplementedError(
        'createGeofencingClient() has not been implemented.');
  }

  void setOnDidEnterRegionIos(Function(String) callback) {
    onDidEnterRegionIos = callback;
  }

  void setOnDidExitRegionIos(Function(String) callback) {
    onDidExitRegionIos = callback;
  }

  Future<String?> checkLocationPermission() {
    throw UnimplementedError(
        'checkLocationPermission() has not been implemented.');
  }

  Future<String?> requestBatteryOptimizationPermission() {
    throw UnimplementedError('requestBatteryOptimizationPermission() has not been implemented');
  }
}
