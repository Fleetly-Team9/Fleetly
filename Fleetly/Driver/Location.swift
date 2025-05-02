//
//  Location.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import CoreLocation

struct Location: Identifiable, Equatable, Codable {
    let id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    static func ==(lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
}
