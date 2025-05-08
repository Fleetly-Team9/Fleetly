import SwiftUI
import FirebaseFirestore

struct RideDetailView: View {
    let ride: Ride
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var actualVehicleNumber: String = "Loading..." // State to hold fetched vehicle number
    
    private let db = Firestore.firestore() // Firestore instance
    
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
    
    // Function to fetch vehicle number from Firestore
    private func fetchVehicleNumber() {
        db.collection("vehicles").document(ride.vehicleId).getDocument { document, error in
            if let document = document,
               let data = document.data(),
               let licensePlate = data["licensePlate"] as? String {
                DispatchQueue.main.async {
                    self.actualVehicleNumber = licensePlate
                }
            } else {
                DispatchQueue.main.async {
                    self.actualVehicleNumber = "Not available"
                }
            }
        }
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
                    DetailsTableView(
                        ride: ride,
                        timeFormatter: timeFormatter,
                        currencyFormatter: currencyFormatter,
                        actualVehicleNumber: actualVehicleNumber // Pass fetched vehicle number
                    )
                    
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
        .onAppear {
            fetchVehicleNumber() // Fetch vehicle number when view appears
        }
    }
}

// Subview for the details table
private struct DetailsTableView: View {
    let ride: Ride
    let timeFormatter: DateFormatter
    let currencyFormatter: NumberFormatter
    let actualVehicleNumber: String // Add parameter for fetched vehicle number
    
    var body: some View {
        VStack(spacing: 0) {
            DetailRowView(title: "Vehicle Number", value: actualVehicleNumber) // Use fetched vehicle number
            DetailRowView(title: "Vehicle Model", value: ride.vehicleModel)
            DetailRowView(title: "Start Time", value: timeFormatter.string(from: ride.startTime))
            DetailRowView(title: "End Time", value: timeFormatter.string(from: ride.endTime))
            DetailRowView(title: "Trip Duration", value: ride.tripDuration)
            DetailRowView(title: "Start Location", value: ride.startLocation)
            DetailRowView(title: "Drop Location", value: ride.endLocation.isEmpty ? "Not available" : ride.endLocation)
            DetailRowView(title: "Mileage", value: String(format: "%.1f km/L", ride.mileage))
            DetailRowView(
                title: "Incidental Charges",
                value: currencyFormatter.string(from: NSNumber(value: ride.charges)) ?? "Rs.\(Int(ride.charges))"
            )
            DetailRowView(
                title: "Maintenance Check",
                value: ride.maintenanceStatus.rawValue,
                valueColor: ride.maintenanceStatus == .verified ? .green : .red
            )
        }
    }
}

// Subview for inspection sections (unchanged)
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
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.red)
                                    )
                            @unknown default:
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No images available")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 12)
        .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
    }
}
