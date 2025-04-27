//
//  Ride.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//
import Foundation

struct Ride: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let startTime: Date
    let endTime: Date
    let startLocation: String
    let endLocation: String
    let mileage: Int
    let maintenanceStatus: MaintenanceStatus
    let vehicleNumber: String
    let vehicleModel: String
    let preInspectionImage: String?
    let postInspectionImage: String?
    let fuelExpense: Double
    let tollExpense: Double
    let miscExpense: Double
    
    // Computed property for charges
    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }
    
    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Ticket Raised"
    }
    
    var tripDuration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

