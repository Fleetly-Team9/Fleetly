//
//  TimeInterval+Formatting.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import Foundation

extension TimeInterval {
    var formattedTravelTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}
