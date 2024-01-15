//
//  LocationDataManager.swift
//  rolling_geofence
//
//  Created by gb on 2023/11/16.
//

import Foundation
import CoreLocation

class LocationDataManager : NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // Location-related properties and delegate methods.
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        // Make sure the devices supports region monitoring.
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            //let maxDistance = locationManager.maximumRegionMonitoringDistance
            let radius = 200.0
            let region = CLCircularRegion(center: center,
                                          radius: radius, identifier: identifier)
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            NSLog("RollingGeofence: Start monitoring on '\(identifier)' (lat:\(center.latitude), lng:\(center.longitude))")
        }
    }
    
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NSLog("RollingGeofence: manager.authorizationStatus = \(manager.authorizationStatus)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            //enableLocationFeatures()
            break
            
        case .restricted, .denied:  // Location services currently unavailable.
            //disableLocationFeatures()
            break
            
        case .notDetermined:        // Authorization not determined yet.
            //manager.requestAlwaysAuthorization()
            break
            
        case .authorizedAlways:
            monitorRegionAtLocation(center: CLLocationCoordinate2D(latitude: 37.521021, longitude: 126.935059), radius: 200, identifier: "office")
            break
            
        default:
            break
        }
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization();
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            NSLog("RollingGeofence: Enter to '\(identifier)'")
            
            //triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            let identifier = region.identifier
            NSLog("RollingGeofence: Exit from '\(identifier)'")
            //triggerTaskAssociatedWithRegionIdentifier(regionID: identifier)
        }
    }
}
