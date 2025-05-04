//
//  Model.swift
//  historyTab
//
//  Created by Sayal Singh on 24/04/25.
//

// MARK: - Model.swift
/*import SwiftUI

struct Ride: Identifiable {
    let id = UUID()
    let date: Date
    let startTime: Date
    let endTime: Date
    let startLocation: String
    let endLocation: String
    let mileage: Int
    let charges: Double
    let maintenanceStatus: MaintenanceStatus
    // Additional fields for detail view
    let vehicleNumber: String
    let vehicleModel: String
    let preInspectionImage: String? // URL or asset name for the image
    let postInspectionImage: String? // URL or asset name for the image
    
    enum MaintenanceStatus: String {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }
    
    // Calculate trip duration in hours and minutes
    var tripDuration: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: endTime)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours) HRS \(minutes) MINS"
            } else {
                return "\(hours) HRS"
            }
        } else {
            return "\(minutes) MINS"
        }
    }
}*/
