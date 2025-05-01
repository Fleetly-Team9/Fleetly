//
//  RideCard.swift
//  FleetlyDriver
//
//  Created by Srijon on 25/04/25.
//
import SwiftUI

struct RideCard: View {
    let ride: Ride
    @Environment(\.colorScheme) var colorScheme
    
    // Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rs. "
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    // Theme-adaptive text color for values
    private var valueTextColor: Color {
        colorScheme == .dark ? Color(.lightGray) : Color(.darkGray)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(dateFormatter.string(from: ride.date))
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Text(timeFormatter.string(from: ride.startTime))
                        .font(.headline)
                        .foregroundColor(valueTextColor)  // Theme-adaptive
                    Text(ride.startLocation)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(timeFormatter.string(from: ride.endTime))
                        .font(.headline)
                        .foregroundColor(valueTextColor)  // Theme-adaptive
                    Text(ride.endLocation)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Mileage")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(ride.mileage) km/L")
                            .foregroundColor(valueTextColor)  // Theme-adaptive
                    }
                    
                    HStack {
                        Text("Incidental Charges")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(currencyFormatter.string(from: NSNumber(value: ride.charges)) ?? "Rs. \(ride.charges)")
                            .foregroundColor(valueTextColor)  // Theme-adaptive
                    }
                    
                    HStack {
                        Text("Maintenance Check")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(ride.maintenanceStatus.rawValue)
                            .foregroundColor(ride.maintenanceStatus == .verified ? .green : .red)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    RideCard(ride: Ride(
        date: Date(),
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600),
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
    ))
}
