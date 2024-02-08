import Flutter
import UIKit
import CoreLocation

public class RollingGeofencePlugin: NSObject, FlutterPlugin {
    var locationDataManager = LocationDataManager()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "rolling_geofence", binaryMessenger: registrar.messenger())
        let instance = RollingGeofencePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.locationDataManager.setChannel(channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "checkFgPermission":
            result(locationDataManager.fgPermission)
        case "checkBgPermission":
            result(locationDataManager.bgPermission)
        case "shouldShowFgRationale":
            result(nil)
        case "shouldShowBgRationale":
            result(nil)
        case "checkLocationPermission":
            result(locationDataManager.fgPermission == true && locationDataManager.bgPermission == true ? "OK" : "Denied")
        case "requestLocationPermission":
            locationDataManager.requestPermission(result: result)
        case "requestBackgroundLocationPermission":
            result(FlutterError(code: "Unsupported", message: "'\(call.method)' is not supported on iOS.", details: nil))
        case "registerGeofence":
            guard let argsMap = call.arguments as? Dictionary<String, Any>,
                  let name = argsMap["name"] as? String,
                  let latitude = argsMap["latitude"] as? Double,
                  let longitude = argsMap["longitude"] as? Double else {
                result(FlutterError(code: call.method, message: "Argument error", details: nil))
                return
            }

            locationDataManager.registerGeofence(center: CLLocationCoordinate2D(latitude: latitude,
                                                                                longitude: longitude),
                                                 radius: 350,
                                                 identifier: name)
            
            result("OK")
        case "createGeofencingClient":
            locationDataManager.createGeofencingClient()
            result("OK")
        case "startSingleLocationRequest":
            locationDataManager.startSingleLocationRequest(result: result)
        case "openApplicationDetailsSettings":
            locationDataManager.openApplicationDetailsSettings()
            result("OK")
        case "isIgnoringBatteryOptimizations":
            result("OK")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}


