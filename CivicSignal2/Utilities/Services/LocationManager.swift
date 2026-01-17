//
//  LocationManager.swift
//  CivicSignal2
//
//  Created by Jeremy Nk on 17/01/2026.
//

import CoreLocation
internal import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    static let shared = LocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation( )
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization( )
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Not Determind")
        case .restricted:
            print("Restricted")
        case .denied:
            print("Access Denied")
        case .authorizedWhenInUse:
            print("Access Granted")
        case .authorizedAlways:
            print("Allowed Always")
        @unknown default:
            print("Default")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
    }
}
