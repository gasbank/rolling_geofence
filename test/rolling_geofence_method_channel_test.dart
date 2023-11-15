import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolling_geofence/rolling_geofence_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelRollingGeofence platform = MethodChannelRollingGeofence();
  const MethodChannel channel = MethodChannel('rolling_geofence');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
