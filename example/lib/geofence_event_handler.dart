import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolling_geofence/rolling_geofence.dart';

@pragma('vm:entry-point')
void onGeofenceEvent(List<String> args) async {
  if (kDebugMode) {
    print('onGeofenceEvent: $args');
  }

  WidgetsFlutterBinding.ensureInitialized();

  final rollingGeofencePlugin = RollingGeofence();
  await rollingGeofencePlugin.createGeofencingClient();
  await rollingGeofencePlugin.updateGeofence();
}
