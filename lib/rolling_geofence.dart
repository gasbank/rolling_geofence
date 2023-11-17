
import 'rolling_geofence_platform_interface.dart';

class RollingGeofence {
  Future<String?> getPlatformVersion() {
    return RollingGeofencePlatform.instance.getPlatformVersion();
  }

  Future<String?> registerGeofence({required String name, required double latitude, required double longitude}) {
    return RollingGeofencePlatform.instance.registerGeofence(name: name, latitude: latitude, longitude: longitude);
  }

  Future<String?> createGeofencingClient() {
    return RollingGeofencePlatform.instance.createGeofencingClient();
  }
}
