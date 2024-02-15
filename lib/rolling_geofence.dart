import 'rolling_geofence_platform_interface.dart';

class RollingGeofence {
  Future<bool?> checkFgPermission() {
    return RollingGeofencePlatform.instance.checkFgPermission();
  }

  Future<bool?> checkBgPermission() {
    return RollingGeofencePlatform.instance.checkBgPermission();
  }

  Future<bool?> shouldShowFgRationale() {
    return RollingGeofencePlatform.instance.shouldShowFgRationale();
  }

  Future<bool?> shouldShowBgRationale() {
    return RollingGeofencePlatform.instance.shouldShowBgRationale();
  }

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
    return RollingGeofencePlatform.instance
        .requestBatteryOptimizationPermission();
  }

  Future<String?> isIgnoringBatteryOptimizations() {
    return RollingGeofencePlatform.instance.isIgnoringBatteryOptimizations();
  }

  Future<bool?> checkBackgroundLocationRationale() {
    return RollingGeofencePlatform.instance.checkBackgroundLocationRationale();
  }

  Future<void> openApplicationDetailsSettings() {
    return RollingGeofencePlatform.instance.openApplicationDetailsSettings();
  }
}
