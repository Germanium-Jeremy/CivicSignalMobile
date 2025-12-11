import Foundation
import CoreLocation

final class LocationService: NSObject, ObservableObject {
    enum LocationError: Error, LocalizedError {
        case permissionDenied
        case permissionRestricted
        case servicesDisabled
        case locationUnavailable
        case reverseGeocodeFailed
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Location permission denied."
            case .permissionRestricted: return "Location permission restricted."
            case .servicesDisabled: return "Location services are disabled."
            case .locationUnavailable: return "Current location is unavailable."
            case .reverseGeocodeFailed: return "Failed to reverse geocode coordinates."
            }
        }
    }
    
    static let shared = LocationService()
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        if CLLocationManager.locationServicesEnabled() == false {
            self.authorizationStatus = .denied
            return
        }
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        }
        manager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.servicesDisabled
        }
        
        if #available(iOS 14.0, *) {
            let status = manager.authorizationStatus
            switch status {
            case .denied, .restricted:
                throw LocationError.permissionDenied
            case .notDetermined:
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    self.manager.requestWhenInUseAuthorization()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        continuation.resume()
                    }
                }
            default: break
            }
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocationCoordinate2D, Error>) in
            self.manager.requestLocation()
            // We'll resolve continuation inside delegate once we receive an update
            self._locationContinuation = continuation
        }
    }
    
    private var _locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    func reverseGeocode(lat: Double, lon: Double) async throws -> (address: String?, district: String?, sector: String?) {
        let location = CLLocation(latitude: lat, longitude: lon)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<(String?, String?, String?), Error>) in
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                guard let pm = placemarks?.first else {
                    cont.resume(throwing: LocationError.reverseGeocodeFailed)
                    return
                }
                let address = [pm.name, pm.thoroughfare].compactMap { $0 }.joined(separator: " ")
                let district = pm.locality ?? pm.subAdministrativeArea
                let sector = pm.subLocality ?? pm.administrativeArea
                cont.resume(returning: (address.isEmpty ? nil : address, district, sector))
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else {
            _locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            _locationContinuation = nil
            return
        }
        lastLocation = loc
        _locationContinuation?.resume(returning: loc.coordinate)
        _locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        _locationContinuation?.resume(throwing: error)
        _locationContinuation = nil
    }
}
