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
    var fgPermission: Bool = false
    var bgPermission: Bool = false
    var geofenceList: [Geofence] = []
    var singleLocationResult: FlutterResult?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
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
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NSLog("RollingGeofence: locationManagerDidChangeAuthorization - manager.authorizationStatus = \(manager.authorizationStatus)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            fgPermission = true
            bgPermission = false
            break
            
        case .restricted, .denied:
            fgPermission = false
            bgPermission = false
            break
            
        case .notDetermined:
            fgPermission = false
            bgPermission = false
            break
            
        case .authorizedAlways:
            fgPermission = true
            bgPermission = true
            break
            
        default:
            break
        }
    }
    
    func requestPermission() {
        if #available(iOS 14.0, *) {
            NSLog("\nRollingGeofence: requestPermission - manager.authorizationStatus = \(locationManager.authorizationStatus)")
        } else {
            // Fallback on earlier versions
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
}
