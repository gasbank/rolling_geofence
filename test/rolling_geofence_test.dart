import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_geofence/rolling_geofence.dart';
import 'package:rolling_geofence/rolling_geofence_platform_interface.dart';
import 'package:rolling_geofence/rolling_geofence_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRollingGeofencePlatform
    with MockPlatformInterfaceMixin
    implements RollingGeofencePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RollingGeofencePlatform initialPlatform = RollingGeofencePlatform.instance;

  test('$MethodChannelRollingGeofence is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRollingGeofence>());
  });

  test('getPlatformVersion', () async {
    RollingGeofence rollingGeofencePlugin = RollingGeofence();
    MockRollingGeofencePlatform fakePlatform = MockRollingGeofencePlatform();
    RollingGeofencePlatform.instance = fakePlatform;

    expect(await rollingGeofencePlugin.getPlatformVersion(), '42');
  });
}
