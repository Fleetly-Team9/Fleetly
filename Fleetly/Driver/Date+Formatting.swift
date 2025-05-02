//
//  Date+Formatting.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import Foundation

extension Date {
    var formattedETA: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
