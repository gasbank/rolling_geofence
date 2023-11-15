import Flutter
import UIKit

public class RollingGeofencePlugin: NSObject, FlutterPlugin {
    var locationDataManager = LocationDataManager()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rolling_geofence", binaryMessenger: registrar.messenger())
    let instance = RollingGeofencePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
