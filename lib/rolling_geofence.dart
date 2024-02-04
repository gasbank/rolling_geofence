import 'rolling_geofence_platform_interface.dart';

class RollingGeofence {
  Future<String?> requestLocationSetting() {
    return RollingGeofencePlatform.instance.requestLocationSetting();
  }

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

  Future<List<double>> startSingleLocationRequest() {
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

  void setOnDidEnterRegionIos(Function(String) callback) {
    return RollingGeofencePlatform.instance.setOnDidEnterRegionIos(callback);
  }

  void setOnDidExitRegionIos(Function(String) callback) {
    return RollingGeofencePlatform.instance.setOnDidExitRegionIos(callback);
  }

  Future<String?> checkLocationPermission() {
    return RollingGeofencePlatform.instance.checkLocationPermission();
  }

  Future<String?> requestBatteryOptimizationPermission() {
    return RollingGeofencePlatform.instance.requestBatteryOptimizationPermission();
  }
}
