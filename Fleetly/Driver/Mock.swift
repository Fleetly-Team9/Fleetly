import Foundation
import SwiftUICore
import SwiftUI
import MapKit
import CoreLocationUI
import CoreLocation


// Vehicle.swift
import Foundation

import SwiftUI

// Assuming Vehicle1 struct is defined like this (you can adjust as needed)
struct Vehicle1: Identifiable {
    let id = UUID()
    let model: String
    let type: String
    let licenseNumber: String
    // Adding an icon name for the image (e.g., SF Symbol or custom asset)
    let iconName: String
}

// Sample mock data (replace with your actual data)
let mockVehicleListView1 = [
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill"),
    Vehicle1(model: "Toyota Camry", type: "Sedan", licenseNumber: "ABC123", iconName: "car.fill"),
    Vehicle1(model: "Ford F-150", type: "Truck", licenseNumber: "XYZ789", iconName: "car.fill"),
    Vehicle1(model: "Tesla Model 3", type: "Electric", licenseNumber: "TES456", iconName: "bolt.car.fill")
]

struct VehicleCardView: View {
    let vehicle: Vehicle1
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                // Icon on the left, styled like a card
                Image(systemName: vehicle.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Vehicle details
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vehicle.model) - \(vehicle.type)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("License Number: \(vehicle.licenseNumber)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Chevron to indicate tappability
                
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

struct MockVehicleListView: View {
    @Binding var selectedVehicle: Vehicle1?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(mockVehicleListView1) { vehicle in
                    Button(action: {
                        selectedVehicle = vehicle
                        dismiss()
                    }) {
                        VehicleCardView(vehicle: vehicle)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Select Vehicle")
        .cornerRadius(30)
    }
}


struct MockVehicleListView_Previews: PreviewProvider {
    @State static var selectedVehicle: Vehicle1? = nil
    static var previews: some View {
        NavigationView {
            MockVehicleListView(selectedVehicle: $selectedVehicle)
        }
    }
}


extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius, style: .continuous)
        self = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}




// Enum for Role
enum Role1: String {
    case driver = "Driver"
}

// Enum for Gender
enum Gender1: String {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

// Driver struct definition
struct Driver1: Identifiable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var aadhaarNumber: String
    var age: String
    var contactNumber: String
    var role: Role1
    var gender: Gender1? // Optional, only for Driver
    var email: String? // Optional, only for Driver
    var licenseNumber: String? // Optional, only for Driver
    var licenseValidUpto: String? // Optional, only for Driver
}

// Mock data for Drivers
let mockDrivers: [Driver1] = [
    Driver1(id: UUID(), firstName: "Ravi", lastName: "Sharma", aadhaarNumber: "1234-5678-9012", age: "35", contactNumber: "9876543210", role: .driver, gender: .male, email: "ravi.sharma@example.com", licenseNumber: "DL12345678", licenseValidUpto: "2026-12-31"),
    Driver1(id: UUID(), firstName: "Anil", lastName: "Kumar", aadhaarNumber: "2345-6789-0123", age: "42", contactNumber: "9876549876", role: .driver, gender: .male, email: "anil.kumar@example.com", licenseNumber: "DL23456789", licenseValidUpto: "2025-11-15"),
    Driver1(id: UUID(), firstName: "Priya", lastName: "Mehta", aadhaarNumber: "4567-8901-2345", age: "28", contactNumber: "9887665432", role: .driver, gender: .female, email: "priya.mehta@example.com", licenseNumber: "DL45678901", licenseValidUpto: "2027-08-23"),
    Driver1(id: UUID(), firstName: "Suresh", lastName: "Singh", aadhaarNumber: "3456-7890-1234", age: "29", contactNumber: "9876554321", role: .driver, gender: .male, email: "suresh.singh@example.com", licenseNumber: "DL34567890", licenseValidUpto: "2024-05-10"),
    Driver1(id: UUID(), firstName: "Ravi", lastName: "Sharma", aadhaarNumber: "1234-5678-9012", age: "35", contactNumber: "9876543210", role: .driver, gender: .male, email: "ravi.sharma@example.com", licenseNumber: "DL12345678", licenseValidUpto: "2026-12-31"),
    Driver1(id: UUID(), firstName: "Anil", lastName: "Kumar", aadhaarNumber: "2345-6789-0123", age: "42", contactNumber: "9876549876", role: .driver, gender: .male, email: "anil.kumar@example.com", licenseNumber: "DL23456789", licenseValidUpto: "2025-11-15"),
    Driver1(id: UUID(), firstName: "Priya", lastName: "Mehta", aadhaarNumber: "4567-8901-2345", age: "28", contactNumber: "9887665432", role: .driver, gender: .female, email: "priya.mehta@example.com", licenseNumber: "DL45678901", licenseValidUpto: "2027-08-23"),
    Driver1(id: UUID(), firstName: "Ravi", lastName: "Sharma", aadhaarNumber: "1234-5678-9012", age: "35", contactNumber: "9876543210", role: .driver, gender: .male, email: "ravi.sharma@example.com", licenseNumber: "DL12345678", licenseValidUpto: "2026-12-31"),
    Driver1(id: UUID(), firstName: "Anil", lastName: "Kumar", aadhaarNumber: "2345-6789-0123", age: "42", contactNumber: "9876549876", role: .driver, gender: .male, email: "anil.kumar@example.com", licenseNumber: "DL23456789", licenseValidUpto: "2025-11-15"),
    Driver1(id: UUID(), firstName: "Priya", lastName: "Mehta", aadhaarNumber: "4567-8901-2345", age: "28", contactNumber: "9887665432", role: .driver, gender: .female, email: "priya.mehta@example.com", licenseNumber: "DL45678901", licenseValidUpto: "2027-08-23"),
    Driver1(id: UUID(), firstName: "Ravi", lastName: "Sharma", aadhaarNumber: "1234-5678-9012", age: "35", contactNumber: "9876543210", role: .driver, gender: .male, email: "ravi.sharma@example.com", licenseNumber: "DL12345678", licenseValidUpto: "2026-12-31"),
    Driver1(id: UUID(), firstName: "Anil", lastName: "Kumar", aadhaarNumber: "2345-6789-0123", age: "42", contactNumber: "9876549876", role: .driver, gender: .male, email: "anil.kumar@example.com", licenseNumber: "DL23456789", licenseValidUpto: "2025-11-15"),
    Driver1(id: UUID(), firstName: "Priya", lastName: "Mehta", aadhaarNumber: "4567-8901-2345", age: "28", contactNumber: "9887665432", role: .driver, gender: .female, email: "priya.mehta@example.com", licenseNumber: "DL45678901", licenseValidUpto: "2027-08-23"),
]

struct DriverCardView: View {
    let driver1: Driver1
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                // Icon on the left, styled like a card
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Driver details
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(driver1.firstName) \(driver1.lastName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Age: \(driver1.age) years")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("License: \(driver1.licenseNumber ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Chevron to indicate tappability
                
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.gray.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

struct MockDriverListView: View {
    @Binding var selectedDriver: Driver1?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(mockDrivers) { driver in
                    Button(action: {
                        selectedDriver = driver
                        dismiss()
                    }) {
                        DriverCardView(driver1: driver)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
        .navigationTitle("Select Driver")
        .cornerRadius(30)
    }
}


struct ParentDriverView: View {
    @State private var showDriverSheet = false
    @State private var selectedDriver: Driver1? // Ensure this is Driver1?

    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    showDriverSheet = true
                }) {
                    Text("Select Driver")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }

                if let driver = selectedDriver {
                    Text("Selected Driver: \(driver.firstName) \(driver.lastName)")
                        .padding()
                }
            }
            .navigationTitle("Driver Selection")
            .sheet(isPresented: $showDriverSheet) {
                MockDriverListView(selectedDriver: $selectedDriver)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
        }
    }
}

struct ParentDriverView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDriverView()
    }
}
