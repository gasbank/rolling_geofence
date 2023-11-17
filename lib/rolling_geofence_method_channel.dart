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

  @override
  Future<String?> registerGeofence({required String name, required double latitude, required double longitude}) async {
    final ret = await methodChannel.invokeMethod<String>('registerGeofence', <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    });
    return ret;
  }

  @override
  Future<String?> createGeofencingClient() async {
    final version = await methodChannel.invokeMethod<String>('createGeofencingClient');
    return version;
  }
}
