//
//  CLLocationDistance+Formatting.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import CoreLocation

extension CLLocationDistance {
    var formattedDistance: String {
        let distanceInKm = self / 1000
        return String(format: "%.1f km", distanceInKm)
    }
}
