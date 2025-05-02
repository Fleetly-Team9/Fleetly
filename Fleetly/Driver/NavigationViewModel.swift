import SwiftUI
import MapKit
import CoreLocation
import Firebase

class NavigationViewModel: NSObject, ObservableObject {
    @Published var trip: Trip?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var startCoordinate: CLLocationCoordinate2D?
    @Published var endCoordinate: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var isLoading = false
    @Published var fuelExpense: Double = 0
    @Published var tollExpense: Double = 0
    @Published var miscExpense: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var startTime: Date?
    @Published var error: String?
    
    private let geocoder = CLGeocoder()
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func loadTrip(_ trip: Trip) {
        self.trip = trip
        self.startTime = Date()
        
        // Geocode the addresses to get coordinates
        convertAddressesToCoordinates()
    }
    
    private func convertAddressesToCoordinates() {
        guard let trip = trip else { return }
        isLoading = true
        error = nil
        
        // Geocode start location
        geocoder.geocodeAddressString(trip.startLocation) { [weak self] startPlacemarks, startError in
            guard let self = self else { return }
            
            if let startError = startError {
                self.isLoading = false
                self.error = "Error geocoding start location: \(startError.localizedDescription)"
                return
            }
            
            guard let startLocation = startPlacemarks?.first?.location else {
                self.isLoading = false
                self.error = "Could not find coordinates for start location"
                return
            }
            
            self.startCoordinate = startLocation.coordinate
            
            // Geocode end location
            self.geocoder.geocodeAddressString(trip.endLocation) { endPlacemarks, endError in
                if let endError = endError {
                    self.isLoading = false
                    self.error = "Error geocoding end location: \(endError.localizedDescription)"
                    return
                }
                
                guard let endLocation = endPlacemarks?.first?.location else {
                    self.isLoading = false
                    self.error = "Could not find coordinates for end location"
                    return
                }
                
                self.endCoordinate = endLocation.coordinate
                
                // Now that we have both coordinates, fetch the route
                self.fetchRoute()
            }
        }
    }
    
    func fetchRoute() {
        guard let startCoordinate = startCoordinate, let endCoordinate = endCoordinate else {
            error = "Missing coordinates for route calculation"
            isLoading = false
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = "Error calculating route: \(error.localizedDescription)"
                return
            }
            
            self.route = response?.routes.first
        }
    }
    
    func startTrip() {
        startTime = Date()
    }
    
    func updateTotalExpenses() {
        totalExpenses = fuelExpense + tollExpense + miscExpense
    }
}

extension NavigationViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
    }
}
