import 'rolling_geofence_platform_interface.dart';

class RollingGeofence {
  Future<String?> requestLocationPermission() {
    return RollingGeofencePlatform.instance.requestLocationPermission();
  }

  Future<String?> requestBackgroundLocationPermission() {
    return RollingGeofencePlatform.instance
        .requestBackgroundLocationPermission();
  }

  Future<String?> startLocationRequest() {
    return RollingGeofencePlatform.instance.startLocationRequest();
  }

  Future<String?> startSingleLocationRequest() {
    return RollingGeofencePlatform.instance.startSingleLocationRequest();
  }

  Future<String?> getPlatformVersion() {
    return RollingGeofencePlatform.instance.getPlatformVersion();
  }

  Future<String?> registerGeofence(
      {required String name,
      required double latitude,
      required double longitude}) {
    return RollingGeofencePlatform.instance
        .registerGeofence(name: name, latitude: latitude, longitude: longitude);
  }

  Future<String?> updateGeofence() {
    return RollingGeofencePlatform.instance.updateGeofence();
  }

  Future<String?> clearGeofence() {
    return RollingGeofencePlatform.instance.clearGeofence();
  }

  Future<String?> createGeofencingClient() {
    return RollingGeofencePlatform.instance.createGeofencingClient();
  }

  void setOnLocationPermissionAllowed(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnLocationPermissionAllowed(callback);
  }

  void setOnLocationPermissionDenied(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnLocationPermissionDenied(callback);
  }

  void setOnLocationPermissionAlreadyAllowed(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnLocationPermissionAlreadyAllowed(callback);
  }

  void setOnBackgroundLocationPermissionAllowed(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnBackgroundLocationPermissionAllowed(callback);
  }

  void setOnBackgroundLocationPermissionDenied(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnBackgroundLocationPermissionDenied(callback);
  }

  void setOnBackgroundLocationPermissionAlreadyAllowed(Function callback) {
    return RollingGeofencePlatform.instance
        .setOnBackgroundLocationPermissionAlreadyAllowed(callback);
  }

  void setOnSuccess(Function(int) callback) {
    return RollingGeofencePlatform.instance.setOnSuccess(callback);
  }

  void setOnError(Function(int) callback) {
    return RollingGeofencePlatform.instance.setOnError(callback);
  }

  void setOnDidEnterRegionIos(Function(String) callback) {
    return RollingGeofencePlatform.instance.setOnDidEnterRegionIos(callback);
  }

  void setOnDidExitRegionIos(Function(String) callback) {
    return RollingGeofencePlatform.instance.setOnDidExitRegionIos(callback);
  }
}
