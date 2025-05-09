/*import SwiftUI
import MapKit
import CoreLocation
import Firebase

class NavigationViewModel: NSObject, ObservableObject {
    @Published var trip: Trip?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var isLoading = false
    @Published var fuelExpense: Double = 0
    @Published var tollExpense: Double = 0
    @Published var miscExpense: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var startTime: Date?
    @Published var pickupLocation: Location?
    @Published var dropLocation: Location?
    @Published var hasDeviatedFromRoute = false
    @Published var deviationDistance: CLLocationDistance = 0
    @Published var lastDeviationTime: Date?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Receipt related properties
    @Published var hasFuelReceipt: Bool = false
    @Published var hasTollReceipt: Bool = false
    @Published var hasMiscReceipt: Bool = false
    @Published var fuelReceipt: Data? = nil
    @Published var tollReceipt: Data? = nil
    @Published var miscReceipt: Data? = nil
    @Published var fuelReceiptDescription: String = ""
    @Published var tollReceiptDescription: String = ""
    @Published var miscReceiptDescription: String = ""
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let routeGeofenceManager = RouteGeofenceManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        
        // Configure for background updates
        if #available(iOS 14.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.showsBackgroundLocationIndicator = true
        }
        
        // Set up deviation callback
        routeGeofenceManager.onDeviationDetected = { [weak self] location, distance in
            DispatchQueue.main.async(execute: DispatchWorkItem {
                self?.hasDeviatedFromRoute = true
                self?.deviationDistance = distance
                self?.lastDeviationTime = Date()
                
                // Log deviation to Firebase
                if let tripId = self?.trip?.id, let vehicleId = self?.trip?.vehicleId, let driverId = self?.trip?.driverId {
                    FirebaseManager.shared.logRouteDeviation(
                        tripId: tripId,
                        vehicleId: vehicleId,
                        driverId: driverId,
                        distance: distance,
                        location: location,
                        timestamp: Date()
                    ) { result in
                        switch result {
                        case .success:
                            print("Successfully logged route deviation to Firebase")
                        case .failure(let error):
                            print("Error logging route deviation: \(error)")
                        }
                    }
                }
            })
        }
    }
    
    func requestLocationPermission() {
        if #available(iOS 14.0, *) {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if #available(iOS 14.0, *) {
                locationManager.startUpdatingLocation()
                print("Started location updates")
            } else {
                // For iOS 13 and below, we can only use when-in-use authorization
                locationManager.startUpdatingLocation()
                print("Started location updates (when-in-use only)")
            }
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    func startTrip(trip: Trip) {
        self.trip = trip
        self.startTime = Date()
        self.hasDeviatedFromRoute = false
        self.deviationDistance = 0
        self.lastDeviationTime = nil
        geocodeLocations()
    }
    
    private func geocodeLocations() {
        guard let trip = trip else { return }
        isLoading = true
        
        // Geocode startLocation
        geocoder.geocodeAddressString(trip.startLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("Error geocoding start location: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            guard let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {
                print("No coordinates found for start location: \(trip.startLocation)")
                self.isLoading = false
                return
            }
            self.pickupLocation = Location(name: trip.startLocation, coordinate: coordinate)
            
            // Geocode endLocation
            self.geocoder.geocodeAddressString(trip.endLocation) { placemarks, error in
                if let error = error {
                    print("Error geocoding end location: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                guard let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {
                    print("No coordinates found for end location: \(trip.endLocation)")
                    self.isLoading = false
                    return
                }
                self.dropLocation = Location(name: trip.endLocation, coordinate: coordinate)
                
                // Fetch route after both locations are geocoded
                self.fetchRoute()
            }
        }
    }
    
    private func fetchRoute() {
        guard let pickup = pickupLocation, let drop = dropLocation else {
            isLoading = false
            return
        }
        
        let request = MKDirections.Request()
        let pickupPlacemark = MKPlacemark(coordinate: pickup.coordinate)
        let dropPlacemark = MKPlacemark(coordinate: drop.coordinate)
        request.source = MKMapItem(placemark: pickupPlacemark)
        request.destination = MKMapItem(placemark: dropPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                return
            }
            if let route = response?.routes.first {
                self.route = route
                // Start monitoring the route with geofencing automatically
                self.routeGeofenceManager.startMonitoring(route: route)
            }
        }
    }
    
    func updateTotalExpenses() {
        totalExpenses = fuelExpense + tollExpense + miscExpense
    }
    
    func stopGeofencing() {
        routeGeofenceManager.stopMonitoring()
        hasDeviatedFromRoute = false
        deviationDistance = 0
        lastDeviationTime = nil
    }
}

extension NavigationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        // Update geofence manager with new location
        routeGeofenceManager.updateLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied by user")
            case .locationUnknown:
                print("Location unknown")
            default:
                print("Location manager error: \(error.localizedDescription)")
            }
        } else {
            print("Location manager error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            print("Unknown authorization status")
        }
    }
}

*/

import SwiftUI
import MapKit
import CoreLocation
import Firebase

class NavigationViewModel: NSObject, ObservableObject {
    @Published var trip: Trip?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var isLoading = false
    @Published var fuelExpense: Double = 0
    @Published var tollExpense: Double = 0
    @Published var miscExpense: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var startTime: Date?
    @Published var pickupLocation: Location?
    @Published var dropLocation: Location?
    @Published var hasDeviatedFromRoute = false
    @Published var deviationDistance: CLLocationDistance = 0
    @Published var lastDeviationTime: Date?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Receipt related properties
    @Published var hasFuelReceipt: Bool = false
    @Published var hasTollReceipt: Bool = false
    @Published var hasMiscReceipt: Bool = false
    @Published var fuelReceipt: Data? = nil
    @Published var tollReceipt: Data? = nil
    @Published var miscReceipt: Data? = nil
    @Published var fuelReceiptDescription: String = ""
    @Published var tollReceiptDescription: String = ""
    @Published var miscReceiptDescription: String = ""
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let routeGeofenceManager = RouteGeofenceManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        
        // Configure for background updates
        if #available(iOS 14.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.showsBackgroundLocationIndicator = true
        }
        
        // Set up deviation callback
        routeGeofenceManager.onDeviationDetected = { [weak self] location, distance in
            DispatchQueue.main.async(execute: DispatchWorkItem {
                self?.hasDeviatedFromRoute = true
                self?.deviationDistance = distance
                self?.lastDeviationTime = Date()
                
                // Log deviation to Firebase
                if let tripId = self?.trip?.id, let vehicleId = self?.trip?.vehicleId, let driverId = self?.trip?.driverId {
                    FirebaseManager.shared.logRouteDeviation(
                        tripId: tripId,
                        vehicleId: vehicleId,
                        driverId: driverId,
                        distance: distance,
                        location: location,
                        timestamp: Date()
                    ) { result in
                        switch result {
                        case .success:
                            print("Successfully logged route deviation to Firebase")
                        case .failure(let error):
                            print("Error logging route deviation: \(error)")
                        }
                    }
                }
            })
        }
    }
    
    func requestLocationPermission() {
        if #available(iOS 14.0, *) {
            locationManager.requestAlwaysAuthorization()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startLocationUpdates() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if #available(iOS 14.0, *) {
                locationManager.startUpdatingLocation()
                print("Started location updates")
            } else {
                // For iOS 13 and below, we can only use when-in-use authorization
                locationManager.startUpdatingLocation()
                print("Started location updates (when-in-use only)")
            }
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    func startTrip(trip: Trip) {
        self.trip = trip
        self.startTime = Date()
        self.hasDeviatedFromRoute = false
        self.deviationDistance = 0
        self.lastDeviationTime = nil
        geocodeLocations()
    }
    
    private func geocodeLocations() {
        guard let trip = trip else { return }
        isLoading = true
        
        // Geocode startLocation
        geocoder.geocodeAddressString(trip.startLocation) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("Error geocoding start location: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            guard let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {
                print("No coordinates found for start location: \(trip.startLocation)")
                self.isLoading = false
                return
            }
            self.pickupLocation = Location(name: trip.startLocation, coordinate: coordinate)
            
            // Geocode endLocation
            self.geocoder.geocodeAddressString(trip.endLocation) { placemarks, error in
                if let error = error {
                    print("Error geocoding end location: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                guard let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {
                    print("No coordinates found for end location: \(trip.endLocation)")
                    self.isLoading = false
                    return
                }
                self.dropLocation = Location(name: trip.endLocation, coordinate: coordinate)
                
                // Fetch route after both locations are geocoded
                self.fetchRoute()
            }
        }
    }
    
    private func fetchRoute() {
        guard let pickup = pickupLocation, let drop = dropLocation else {
            isLoading = false
            return
        }
        
        let request = MKDirections.Request()
        let pickupPlacemark = MKPlacemark(coordinate: pickup.coordinate)
        let dropPlacemark = MKPlacemark(coordinate: drop.coordinate)
        request.source = MKMapItem(placemark: pickupPlacemark)
        request.destination = MKMapItem(placemark: dropPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                return
            }
            if let route = response?.routes.first {
                self.route = route
                // Start monitoring the route with geofencing automatically
                self.routeGeofenceManager.startMonitoring(route: route)
            }
        }
    }
    
    func updateTotalExpenses() {
        totalExpenses = fuelExpense + tollExpense + miscExpense
    }
    
    func stopGeofencing() {
        routeGeofenceManager.stopMonitoring()
        hasDeviatedFromRoute = false
        deviationDistance = 0
        lastDeviationTime = nil
    }
    
    func resetTrip() {
            // Stop geofencing
            stopGeofencing()

            // Reset trip-related state
            route = nil
            pickupLocation = nil
            dropLocation = nil
            userLocation = nil
            fuelExpense = 0.0
            tollExpense = 0.0
            miscExpense = 0.0
            totalExpenses = 0.0
            fuelReceipt = nil
            tollReceipt = nil
            miscReceipt = nil
            hasFuelReceipt = false
            hasTollReceipt = false
            hasMiscReceipt = false
            fuelReceiptDescription = ""
            tollReceiptDescription = ""
            miscReceiptDescription = ""
            startTime = nil
            hasDeviatedFromRoute = false
            deviationDistance = 0.0
        }
    
}

extension NavigationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        // Update geofence manager with new location
        routeGeofenceManager.updateLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied by user")
            case .locationUnknown:
                print("Location unknown")
            default:
                print("Location manager error: \(error.localizedDescription)")
            }
        } else {
            print("Location manager error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            print("Unknown authorization status")
        }
    }
    
    
    
}


