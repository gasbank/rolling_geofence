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

  Function? onLocationPermissionAllowed;
  Function? onLocationPermissionDenied;
  Function? onLocationPermissionAlreadyAllowed;

  Function? onBackgroundLocationPermissionAllowed;
  Function? onBackgroundLocationPermissionDenied;
  Function? onBackgroundLocationPermissionAlreadyAllowed;

  Function(int)? onSuccess;
  Function(int)? onError;

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<String?> registerGeofence(
      {required String name,
      required double latitude,
      required double longitude}) {
    throw UnimplementedError('registerGeofence() has not been implemented.');
  }

  Future<String?> createGeofencingClient() {
    throw UnimplementedError(
        'createGeofencingClient() has not been implemented.');
  }

  void setOnLocationPermissionAllowed(Function callback) {
    onLocationPermissionAllowed = callback;
  }

  void setOnLocationPermissionDenied(Function callback) {
    onLocationPermissionDenied = callback;
  }

  void setOnLocationPermissionAlreadyAllowed(Function callback) {
    onLocationPermissionAlreadyAllowed = callback;
  }

  void setOnBackgroundLocationPermissionAllowed(Function callback) {
    onBackgroundLocationPermissionAllowed = callback;
  }

  void setOnBackgroundLocationPermissionDenied(Function callback) {
    onBackgroundLocationPermissionDenied = callback;
  }

  void setOnBackgroundLocationPermissionAlreadyAllowed(Function callback) {
    onBackgroundLocationPermissionAlreadyAllowed = callback;
  }

  void setOnSuccess(Function(int) callback) {
    onSuccess = callback;
  }

  void setOnError(Function(int) callback) {
    onError = callback;
  }
}
