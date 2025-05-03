//
//  RideDetailsView.swift
//  historyTab
//
//  Created by user@90 on 24/04/25.
//


/*struct RideDetailView: View {
    let ride: Ride
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rs."
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date header
                Text(dateFormatter.string(from: ride.date))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                
                // Details table
                VStack(spacing: 0) {
                    // Vehicle Number
                    DetailRowView(title: "Vehicle Number", value: ride.vehicleNumber)
                    
                    // Vehicle Model
                    DetailRowView(title: "Vehicle Model", value: ride.vehicleModel)
                    
                    // Start Time
                    DetailRowView(title: "Start Time", value: timeFormatter.string(from: ride.startTime))
                    
                    // End Time
                    DetailRowView(title: "End Time", value: timeFormatter.string(from: ride.endTime))
                    
                    // Trip Duration
                    DetailRowView(title: "Trip Duration", value: ride.tripDuration)
                    
                    // Start Location
                    DetailRowView(title: "Start Location", value: ride.startLocation)
                    
                    // Drop Location
                    DetailRowView(title: "Drop Location", value: ride.endLocation)
                    
                    // Mileage
                    DetailRowView(title: "Mileage", value: "\(ride.mileage) km/L")
                    
                    // Incidental Charges
                    DetailRowView(title: "Incidental Charges", value: "\(currencyFormatter.string(from: NSNumber(value: ride.charges)) ?? "Rs.\(Int(ride.charges))")")
                    
                    // Maintenance Check
                    DetailRowView(
                        title: "Maintenance Check",
                        value: ride.maintenanceStatus.rawValue,
                        valueColor: ride.maintenanceStatus == .verified ? .green : .red
                    )
                    
                    // Pre-inspection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pre-inspection")
                            .font(.body)
                            .padding(.leading)
                            .padding(.top, 12)
                            .padding(.bottom, 5)
                        
                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 80)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                    Divider()
                    
                    // Post-inspection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Post-inspection")
                            .font(.body)
                            .padding(.leading)
                            .padding(.top, 12)
                            .padding(.bottom, 5)
                        
                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 80)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                }
                .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                        Text("Past Rides")
                            .foregroundColor(.blue)
                    }
                }
            }
        )
    }
}*/

import SwiftUI

/*struct RideDetailView: View {
    let ride: Ride
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rs."
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date header
                Text(dateFormatter.string(from: ride.date))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                
                // Details table
                VStack(spacing: 0) {
                    // Vehicle Number
                    DetailRowView(title: "Vehicle Number", value: ride.vehicleNumber)
                    
                    // Vehicle Model
                    DetailRowView(title: "Vehicle Model", value: ride.vehicleModel)
                    
                    // Start Time
                    DetailRowView(title: "Start Time", value: timeFormatter.string(from: ride.startTime))
                    
                    // End Time
                    DetailRowView(title: "End Time", value: timeFormatter.string(from: ride.endTime))
                    
                    // Trip Duration
                    DetailRowView(title: "Trip Duration", value: ride.tripDuration)
                    
                    // Start Location
                    DetailRowView(title: "Start Location", value: ride.startLocation)
                    
                    // Drop Location
                    DetailRowView(title: "Drop Location", value: ride.endLocation ?? "Not available")
                    
                    // Mileage
                    DetailRowView(title: "Mileage", value: String(format: "%.1f km/L", ride.mileage))
                    
                    // Incidental Charges
                    DetailRowView(title: "Incidental Charges", value: "\(currencyFormatter.string(from: NSNumber(value: ride.charges)) ?? "Rs.\(Int(ride.charges))")")
                    
                    // Maintenance Check
                    DetailRowView(
                        title: "Maintenance Check",
                        value: ride.maintenanceStatus.rawValue,
                        valueColor: ride.maintenanceStatus == .verified ? .green : .red
                    )
                    
                    // Pre-inspection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pre-inspection")
                            .font(.body)
                            .padding(.leading)
                            .padding(.top, 12)
                            .padding(.bottom, 5)
                        
                        if let imageURLs = ride.preInspectionImage, !imageURLs.isEmpty {
                            HStack(spacing: 10) {
                                ForEach(imageURLs.prefix(4), id: \.self) { url in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 80)
                                    // In a real app, load the image using a library like SDWebImageSwiftUI
                                }
                            }
                        } else {
                            Text("No images available")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 12)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                    Divider()
                    
                    // Post-inspection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Post-inspection")
                            .font(.body)
                            .padding(.leading)
                            .padding(.top, 12)
                            .padding(.bottom, 5)
                        
                        if let imageURLs = ride.postInspectionImage, !imageURLs.isEmpty {
                            HStack(spacing: 10) {
                                ForEach(imageURLs.prefix(4), id: \.self) { url in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 80)
                                    // In a real app, load the image using a library like SDWebImageSwiftUI
                                }
                            }
                        } else {
                            Text("No images available")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 12)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                }
                .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                        Text("Past Rides")
                            .foregroundColor(.blue)
                    }
                }
            }
        )
    }
}
*/
import SwiftUI

struct RideDetailView: View {
    let ride: Ride
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rs."
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date header
                Text(dateFormatter.string(from: ride.date))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                
                // Details table and inspections
                VStack(spacing: 0) {
                    DetailsTableView(ride: ride, timeFormatter: timeFormatter, currencyFormatter: currencyFormatter)
                    
                    InspectionView(
                        title: "Pre-inspection",
                        imageURLs: ride.preInspectionImage,
                        colorScheme: colorScheme
                    )
                    Divider()
                    
                    InspectionView(
                        title: "Post-inspection",
                        imageURLs: ride.postInspectionImage,
                        colorScheme: colorScheme
                    )
                }
                .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding()
            }
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                        Text("Past Rides")
                            .foregroundColor(.blue)
                    }
                }
            }
        )
    }
}

// Subview for the details table
private struct DetailsTableView: View {
    let ride: Ride
    let timeFormatter: DateFormatter
    let currencyFormatter: NumberFormatter
    
    var body: some View {
        VStack(spacing: 0) {
            DetailRowView(title: "Vehicle Number", value: ride.vehicleNumber)
            DetailRowView(title: "Vehicle Model", value: ride.vehicleModel)
            DetailRowView(title: "Start Time", value: timeFormatter.string(from: ride.startTime))
            DetailRowView(title: "End Time", value: timeFormatter.string(from: ride.endTime))
            DetailRowView(title: "Trip Duration", value: ride.tripDuration)
            DetailRowView(title: "Start Location", value: ride.startLocation)
            DetailRowView(title: "Drop Location", value: ride.endLocation ?? "Not available")
            DetailRowView(title: "Mileage", value: String(format: "%.1f km/L", ride.mileage))
            DetailRowView(
                title: "Incidental Charges",
                value: "\(currencyFormatter.string(from: NSNumber(value: ride.charges)) ?? "Rs.\(Int(ride.charges))")"
            )
            DetailRowView(
                title: "Maintenance Check",
                value: ride.maintenanceStatus.rawValue,
                valueColor: ride.maintenanceStatus == .verified ? .green : .red
            )
        }
    }
}

// Subview for inspection sections
private struct InspectionView: View {
    let title: String
    let imageURLs: [String]?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.body)
                .padding(.leading)
                .padding(.top, 12)
                .padding(.bottom, 5)
            
            if let imageURLs = imageURLs, !imageURLs.isEmpty {
                HStack(spacing: 10) {
                    ForEach(imageURLs.prefix(4), id: \.self) { url in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 80)
                        // In a real app, load the image using a library like SDWebImageSwiftUI
                    }
                }
            } else {
                Text("No images available")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            //.padding(.bottom, 12)
        }
        .padding(.bottom,12)
        .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
    }
}

