//
//  PastRideViewModel.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//
import Foundation
import SwiftUI

class PastRidesViewModel: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init() {
        loadRides()
    }
    
    func loadRides() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let sampleRides: [Ride] = [
            // April 26, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-26 08:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-26 08:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-26 09:00") ?? Date(),
                startLocation: "Chennai",
                endLocation: "Mysuru",
                mileage: 66,
                maintenanceStatus: .verified,
                vehicleNumber: "KA01AB4321",
                vehicleModel: "Swift Dzire",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 200.0,
                tollExpense: 50.0,
                miscExpense: 20.0
            ),
            Ride(
                date: dateFormatter.date(from: "2025-04-26 10:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-26 10:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-26 13:00") ?? Date(),
                startLocation: "Chennai",
                endLocation: "Mysuru",
                mileage: 70,
                maintenanceStatus: .ticketRaised,
                vehicleNumber: "KA02CD5678",
                vehicleModel: "Toyota Innova",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 300.0,
                tollExpense: 80.0,
                miscExpense: 30.0
            ),
            Ride(
                date: dateFormatter.date(from: "2025-04-26 15:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-26 15:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-26 16:30") ?? Date(),
                startLocation: "Mysuru",
                endLocation: "Bangalore",
                mileage: 45,
                maintenanceStatus: .verified,
                vehicleNumber: "KA03EF9012",
                vehicleModel: "Honda City",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 150.0,
                tollExpense: 40.0,
                miscExpense: 10.0
            ),
            
            // April 24, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-24 07:30") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-24 07:30") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-24 09:00") ?? Date(),
                startLocation: "Chennai",
                endLocation: "Pondicherry",
                mileage: 42,
                maintenanceStatus: .verified,
                vehicleNumber: "KA04GH3456",
                vehicleModel: "Hyundai Verna",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 120.0,
                tollExpense: 30.0,
                miscExpense: 15.0
            ),
            Ride(
                date: dateFormatter.date(from: "2025-04-24 14:30") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-24 14:30") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-24 16:45") ?? Date(),
                startLocation: "Pondicherry",
                endLocation: "Chennai",
                mileage: 44,
                maintenanceStatus: .ticketRaised,
                vehicleNumber: "KA09AB7654",
                vehicleModel: "Toyota Fortuner",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 130.0,
                tollExpense: 35.0,
                miscExpense: 20.0
            ),
            
            // April 22, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-22 09:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-22 09:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-22 11:00") ?? Date(),
                startLocation: "Mysuru",
                endLocation: "Bangalore",
                mileage: 48,
                maintenanceStatus: .verified,
                vehicleNumber: "KA05IJ7890",
                vehicleModel: "Maruti Swift",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 140.0,
                tollExpense: 25.0,
                miscExpense: 10.0
            ),
            Ride(
                date: dateFormatter.date(from: "2025-04-22 16:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-22 16:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-22 18:30") ?? Date(),
                startLocation: "Bangalore",
                endLocation: "Mysuru",
                mileage: 52,
                maintenanceStatus: .ticketRaised,
                vehicleNumber: "KA08MN4567",
                vehicleModel: "Mahindra XUV500",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 160.0,
                tollExpense: 45.0,
                miscExpense: 25.0
            ),
            
            // April 20, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-20 12:00") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-20 12:00") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-20 14:30") ?? Date(),
                startLocation: "Chennai",
                endLocation: "Vellore",
                mileage: 75,
                maintenanceStatus: .verified,
                vehicleNumber: "KA06KL1234",
                vehicleModel: "Tata Nexon",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 250.0,
                tollExpense: 60.0,
                miscExpense: 40.0
            ),
            
            // April 18, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-18 08:30") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-18 08:30") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-18 10:45") ?? Date(),
                startLocation: "Bangalore",
                endLocation: "Hassan",
                mileage: 62,
                maintenanceStatus: .ticketRaised,
                vehicleNumber: "KA07OP8901",
                vehicleModel: "Mahindra Thar",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 200.0,
                tollExpense: 50.0,
                miscExpense: 30.0
            ),
            
            // April 15, 2025
            Ride(
                date: dateFormatter.date(from: "2025-04-15 09:15") ?? Date(),
                startTime: dateFormatter.date(from: "2025-04-15 09:15") ?? Date(),
                endTime: dateFormatter.date(from: "2025-04-15 12:30") ?? Date(),
                startLocation: "Mysuru",
                endLocation: "Coorg",
                mileage: 95,
                maintenanceStatus: .ticketRaised,
                vehicleNumber: "KA10QR2345",
                vehicleModel: "Kia Seltos",
                preInspectionImage: nil,
                postInspectionImage: nil,
                fuelExpense: 300.0,
                tollExpense: 70.0,
                miscExpense: 50.0
            )
        ]
        
        rides = sampleRides
    }
    
    func filteredRides(for date: Date) -> [Ride] {
        return rides.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func daysInMonth() -> [[Date?]] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let numDays = range.count
        
        // Find the first weekday
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let weekdayOffset = firstWeekday - 1 // 1-based to 0-based
        
        var days: [[Date?]] = []
        var week: [Date?] = Array(repeating: nil, count: 7)
        
        // Fill in the days
        for day in 1...numDays {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) else { continue }
            
            let index = (weekdayOffset + day - 1) % 7
            let weekIndex = (weekdayOffset + day - 1) / 7
            
            if index == 0 && day > 1 {
                days.append(week)
                week = Array(repeating: nil, count: 7)
            }
            
            week[index] = date
        }
        
        // Add the last week
        days.append(week)
        
        return days
    }
    
    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    func isDateInCurrentMonth(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    func dayHasRides(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return rides.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
}
