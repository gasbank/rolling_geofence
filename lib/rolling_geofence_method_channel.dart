import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rolling_geofence_platform_interface.dart';

/// An implementation of [RollingGeofencePlatform] that uses method channels.
class MethodChannelRollingGeofence extends RollingGeofencePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rolling_geofence');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
