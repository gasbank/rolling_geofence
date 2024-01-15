import Flutter
import UIKit
import CoreLocation

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
        case "registerGeofence":
            guard let argsMap = call.arguments as? Dictionary<String, Any>,
                  let name = argsMap["name"] as? String,
                  let latitude = argsMap["latitude"] as? Double,
                  let longitude = argsMap["longitude"] as? Double else {
                result(FlutterError(code: call.method, message: "Argument error", details: nil))
                return
            }
            
            locationDataManager.monitorRegionAtLocation(center: CLLocationCoordinate2D(latitude: latitude,
                                                                                       longitude: longitude),
                                                        radius: 200,
                                                        identifier: name)
            
            result("ok")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}


