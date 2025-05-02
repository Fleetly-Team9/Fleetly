import SwiftUI
import MapKit
import CoreLocation

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
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func startTrip(trip: Trip) {
        self.trip = trip
        self.startTime = Date()
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
            self.route = response?.routes.first
        }
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
