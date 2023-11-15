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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
