import Foundation
import CoreLocation
import Flutter

struct Geofence {
    let lat: Double
    let lng: Double
    let radius: Double
    let identifier: String
}

class LocationDataManager : NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    var channel: FlutterMethodChannel?
    var fgPermission: Bool?
    var bgPermission: Bool?
    var geofenceList: [Geofence] = []
    var permissionResult: FlutterResult?
    var singleLocationResult: FlutterResult?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        //locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func setChannel(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func registerGeofence(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        geofenceList.append(Geofence(lat: center.latitude, lng: center.longitude, radius: radius, identifier: identifier))
    }
    
    func createGeofencingClient() {
        for geofence in geofenceList {
            monitorRegionAtLocation(center: CLLocationCoordinate2D(latitude: geofence.lat,
                                                                   longitude: geofence.lng),
                                    radius: geofence.radius,
                                    identifier: geofence.identifier)
        }
        
        geofenceList.removeAll()
    }
    
    // Location-related properties and delegate methods.
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        // Make sure the devices supports region monitoring.
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            //let maxDistance = locationManager.maximumRegionMonitoringDistance
            let region = CLCircularRegion(center: center,
                                          radius: radius,
                                          identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            NSLog("RollingGeofence: Start monitoring on '\(identifier)' (lat:\(center.latitude), lng:\(center.longitude), radius:\(radius))")
        }
    }
    
    // iOS 14 미만 옛날 기기에서 작동하는 콜백
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("RollingGeofence: locationManager didChangeAuthorization - status = \(status)")
        
        didChangeAuth(status: status)
    }
        
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NSLog("RollingGeofence: locationManagerDidChangeAuthorization - manager.authorizationStatus = \(manager.authorizationStatus)")
        
        didChangeAuth(status: manager.authorizationStatus)
    }
    
    fileprivate func callPermissionResult() {
        if permissionResult != nil {
            permissionResult!(fgPermission == true && bgPermission == true ? "OK" : "Denied")
            permissionResult = nil
        }
    }
    
    func didChangeAuth(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            fgPermission = true
            bgPermission = false
            break
            
        case .restricted, .denied:
            fgPermission = false
            bgPermission = false
            break
            
        case .notDetermined:
            fgPermission = nil
            bgPermission = nil
            break
            
        case .authorizedAlways:
            fgPermission = true
            bgPermission = true
            break
            
        default:
            break
        }
        
        callPermissionResult()
    }
    
    func requestPermission(result: @escaping FlutterResult) {
        // 이미 권한 획득이 끝났다면
        if fgPermission == true && bgPermission == true {
            result("OK")
            return
        }
        
        if #available(iOS 14.0, *) {
            NSLog("\nRollingGeofence: requestPermission - manager.authorizationStatus = \(locationManager.authorizationStatus)")
        } else {
            // Fallback on earlier versions
        }
        
        if permissionResult != nil {
            result(FlutterError(code: "OverlappedRequest", message: "requestPermission was called again before the previous was not finished", details: nil))
            return
        }
        permissionResult = result
        
        if (fgPermission != nil && bgPermission != nil) {
            callPermissionResult()
            return
        }
        
        locationManager.requestAlwaysAuthorization()
    }
    
    func startSingleLocationRequest(result: @escaping FlutterResult) {
        if singleLocationResult != nil {
            result(FlutterError(code: "OverlappedRequest", message: "startSingleLocationRequest was called again before the previous was not finished", details: nil))
            return
        }
        singleLocationResult = result
        
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var doubleArrList: [Double] = []
        
        for loc in locations {
            NSLog("Location didUpdateLocations: lat \(loc.coordinate.latitude) lng \(loc.coordinate.longitude)")
            doubleArrList.append(loc.coordinate.latitude)
            doubleArrList.append(loc.coordinate.longitude)
        }
        
        if singleLocationResult != nil {
            singleLocationResult!(doubleArrList)
            singleLocationResult = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Location didFailWithError: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        NSLog("Location monitoringDidFailFor: region \(String(describing: region)) error \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            NSLog("RollingGeofence: Enter to '\(identifier)'")
            
            if channel != nil {
                channel?.invokeMethod("onDidEnterRegionIos", arguments: ["name": identifier])
            }
            
            //triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            NSLog("RollingGeofence: Exit from '\(identifier)'")
            
            if channel != nil {
                channel?.invokeMethod("onDidExitRegionIos", arguments: ["name": identifier])
            }
            
            //triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
    
    func openApplicationDetailsSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
}
