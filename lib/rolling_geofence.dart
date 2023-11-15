
import 'rolling_geofence_platform_interface.dart';

class RollingGeofence {
  Future<String?> getPlatformVersion() {
    return RollingGeofencePlatform.instance.getPlatformVersion();
  }
}
