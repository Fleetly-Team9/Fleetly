import SwiftUI
import FirebaseFirestore

// MARK: - Modified Trip Parsing Method
extension Trip {
    static func fromQueryDocument(_ document: QueryDocumentSnapshot) -> Trip? {
        let data = document.data()
        guard
            let driverId    = data["driverId"]     as? String,
            let vehicleId   = data["vehicleId"]    as? String,
            let startLoc    = data["startLocation"] as? String,
            let endLoc      = data["endLocation"]  as? String,
            let dateStr     = data["date"]         as? String,
            let timeStr     = data["time"]         as? String,
            let startTs     = (data["startTime"]   as? Timestamp)?.dateValue(),
            let statusStr   = data["status"]       as? String,
            let status      = Trip.TripStatus(rawValue: statusStr),
            let vehicleType = data["vehicleType"]  as? String
        else { return nil }

        return Trip(
            id: document.documentID, // Use the document ID directly
            driverId: driverId,
            vehicleId: vehicleId,
            startLocation: startLoc,
            endLocation: endLoc,
            date: dateStr,
            time: timeStr,
            startTime: startTs,
            status: status,
            vehicleType: vehicleType,
            passengers: data["passengers"] as? Int,
            loadWeight: data["loadWeight"] as? Double
        )
    }
}

// MARK: - ViewModels
class TripViewModel: ObservableObject {
    @Published var allTrips: [Trip] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var searchText: String = ""
    @Published var statusFilter: Trip.TripStatus? = nil
    @Published var vehicleTypeFilter: String? = nil
    @Published var activeFilters: [String] = []
    @Published var showFilterSheet: Bool = false

    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    private let db = Firestore.firestore()

    // Modified to filter trips based on search text and filters
    var displayTrips: [Trip] {
        let filtered = allTrips.filter { trip in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                trip.id.lowercased().contains(searchText.lowercased()) ||
                trip.startLocation.lowercased().contains(searchText.lowercased()) ||
                trip.endLocation.lowercased().contains(searchText.lowercased()) ||
                trip.date.lowercased().contains(searchText.lowercased()) ||
                trip.time.lowercased().contains(searchText.lowercased()) ||
                trip.vehicleType.lowercased().contains(searchText.lowercased())
            
            // Status filter
            let matchesStatus = statusFilter == nil || trip.status == statusFilter!
            
            // Vehicle type filter
            let matchesVehicleType = vehicleTypeFilter == nil || trip.vehicleType == vehicleTypeFilter!
            
            return matchesSearch && matchesStatus && matchesVehicleType
        }
        
        // Sort by date (most recent first)
        return filtered.sorted { $0.startTime > $1.startTime }
    }
    
    func updateActiveFilters() {
        activeFilters.removeAll()
        
        if statusFilter != nil {
            activeFilters.append("Status: \(statusFilter!.displayName)")
        }
        
        if vehicleTypeFilter != nil {
            activeFilters.append("Vehicle: \(vehicleTypeFilter!)")
        }
    }
    
    func clearAllFilters() {
        statusFilter = nil
        vehicleTypeFilter = nil
        updateActiveFilters()
    }

    func fetchTrips() {
        isLoading = true
        error = nil

        db.collection("trips").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.allTrips = []
                    return
                }

                self.allTrips = documents.compactMap { Trip.fromQueryDocument($0) }
            }
        }
    }

    func trips(for status: Trip.TripStatus) -> [Trip] {
        allTrips.filter { $0.status == status }
    }

    func allStatuses() -> [Trip.TripStatus] {
        Array(Set(allTrips.map { $0.status })).sorted { $0.rawValue < $1.rawValue }
    }
    
    func allVehicleTypes() -> [String] {
        Array(Set(allTrips.map { $0.vehicleType })).sorted()
    }
}

class TripDetailViewModel: ObservableObject {
    @Published var driverName: String = ""
    @Published var vehicleInfo: String = ""
    @Published var error: String? = nil // Optional: To handle errors

    private let db = Firestore.firestore()

    func fetchDriverName(by driverId: String) {
        db.collection("users").document(driverId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let name = data["name"] as? String {
                DispatchQueue.main.async {
                    self.driverName = name
                }
            } else {
                DispatchQueue.main.async {
                    self.driverName = "Unknown Driver"
                }
            }
        }
    }

    func fetchVehicleInfo(by vehicleId: String) {
        db.collection("vehicles").document(vehicleId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let make = data["make"] as? String,
               let model = data["model"] as? String {
                DispatchQueue.main.async {
                    self.vehicleInfo = "\(make) \(model)"
                }
            } else {
                DispatchQueue.main.async {
                    self.vehicleInfo = "Unknown Vehicle"
                }
            }
        }
    }

    // New method to update trip status
    func updateTripStatus(tripId: String, status: Trip.TripStatus, completion: @escaping (Error?) -> Void) {
        db.collection("trips").document(tripId).updateData([
            "status": status.rawValue
        ]) { error in
            DispatchQueue.main.async {
                self.error = error?.localizedDescription
                completion(error)
            }
        }
    }
}

// MARK: - Active Trips View (Renamed to AllTripsView)
struct AllTripsView: View {
    @StateObject private var viewModel = TripViewModel()
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.top, 8) // Reduced top padding
                        .padding(.bottom, 8)
                    
                    // Filter chips
                    if !viewModel.activeFilters.isEmpty {
                        activeFilterChips
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading trips...")
                        Spacer()
                    } else if let error = viewModel.error {
                        Spacer()
                        VStack {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                            Button("Try Again") {
                                viewModel.fetchTrips()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                    } else if viewModel.displayTrips.isEmpty {
                        Spacer()
                        VStack {
                            Text("No trips found")
                                .font(.headline)
                            Button("Refresh") {
                                viewModel.fetchTrips()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.displayTrips) { trip in
                                    TripCard(trip: trip) {
                                        selectedTrip = trip
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8) // Reduced vertical padding
                        }
                        .refreshable {
                            viewModel.fetchTrips()
                        }
                    }
                }
            }
            .navigationTitle("Overall Trips")
            .navigationBarTitleDisplayMode(.inline) // Use inline to reduce space
            .sheet(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterView(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                viewModel.fetchTrips()
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search trips...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Filter Chips
    private var activeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.activeFilters, id: \.self) { filter in
                    HStack(spacing: 4) {
                        if filter.hasPrefix("Status:") {
                            let statusName = filter.replacingOccurrences(of: "Status: ", with: "")
                            let tripStatus = Trip.TripStatus.allCases.first(where: { $0.displayName == statusName })
                            if let status = tripStatus {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Text(filter)
                            .font(.footnote)
                            .padding(.leading, 8)
                        
                        Button(action: {
                            if filter.hasPrefix("Status:") {
                                viewModel.statusFilter = nil
                            } else if filter.hasPrefix("Vehicle:") {
                                viewModel.vehicleTypeFilter = nil
                            }
                            viewModel.updateActiveFilters()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .imageScale(.small)
                        }
                        .padding(.trailing, 4)
                    }
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(16)
                }
                
                if viewModel.activeFilters.count > 1 {
                    Button("Clear All") {
                        viewModel.clearAllFilters()
                    }
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

//// MARK: - Trip Status Definition
extension Trip {
    enum TripStatus: String, CaseIterable, Codable{
        case assigned = "assigned"
        case inProgress = "inProgress"
        case completed = "completed"
        case cancelled = "cancelled"
        case delayed = "delayed"
        
        var displayName: String {
            switch self {
            case .assigned:
                return "Assigned"
            case .inProgress:
                return "In Progress"
            case .completed:
                return "Completed"
            case .cancelled:
                return "Cancelled"
            case .delayed:
                return "Delayed"
            }
        }
        
        var color: Color {
            switch self {
            case .assigned:
                return .blue
            case .inProgress:
                return .orange
            case .completed:
                return .green
            case .cancelled:
                return .red
            case .delayed:
                return .yellow
            }
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @ObservedObject var viewModel: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State private var tempStatusFilter: Trip.TripStatus?
    @State private var tempVehicleTypeFilter: String?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Status")) {
                    Button("All") {
                        tempStatusFilter = nil
                    }
                    .foregroundColor(.primary)
                    
                    // Using predefined status options instead of dynamically fetching
                    ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                        Button(action: {
                            tempStatusFilter = status
                        }) {
                            HStack {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 10, height: 10)
                                Text(status.displayName)
                                Spacer()
                                if tempStatusFilter == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Vehicle Type")) {
                    Button("All") {
                        tempVehicleTypeFilter = nil
                    }
                    .foregroundColor(.primary)
                    
                    ForEach(viewModel.allVehicleTypes(), id: \.self) { vehicle in
                        Button(action: {
                            tempVehicleTypeFilter = vehicle
                        }) {
                            HStack {
                                Text(vehicle)
                                Spacer()
                                if tempVehicleTypeFilter == vehicle {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Filter Trips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.statusFilter = tempStatusFilter
                        viewModel.vehicleTypeFilter = tempVehicleTypeFilter
                        viewModel.updateActiveFilters()
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                // Initialize temporary filters with current values
                tempStatusFilter = viewModel.statusFilter
                tempVehicleTypeFilter = viewModel.vehicleTypeFilter
            }
        }
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: Trip
    let onTap: () -> Void
    @StateObject private var viewModel = TripDetailViewModel()
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Trip ID: \(trip.id)")
                        .font(.headline)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trip.status.color)
                            .frame(width: 8, height: 8)
                        Text(trip.status.displayName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: "car.fill") // 🚗 Vehicle logo
                        .foregroundColor(.blue)
                        .imageScale(.large)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Driver: \(viewModel.driverName)")
                            .font(.subheadline)
                        Text("Vehicle: \(viewModel.vehicleInfo)")
                            .font(.subheadline)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("From: \(trip.startLocation)")
                    Text("To: \(trip.endLocation)")
                    Text("Date: \(trip.date) • \(trip.time)")
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            viewModel.fetchDriverName(by: trip.driverId)
            viewModel.fetchVehicleInfo(by: trip.vehicleId)
        }
    }
}

// MARK: - Trip Detail View
struct TripDetailView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TripDetailViewModel()
    @State private var isUpdating = false // To show loading state
    @State private var showErrorAlert = false // To show error alert
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox(label: Text("Trip Info").font(.headline)) {
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(label: "Trip ID", value: trip.id)
                            DetailRow(label: "Vehicle", value: viewModel.vehicleInfo)
                            DetailRow(label: "Driver", value: viewModel.driverName)
                            DetailRow(label: "From", value: trip.startLocation)
                            DetailRow(label: "To", value: trip.endLocation)
                            HStack(alignment: .top) {
                                Text("Status")
                                    .foregroundColor(.secondary)
                                    .frame(width: 100, alignment: .leading)
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(trip.status.color)
                                        .frame(width: 10, height: 10)
                                    Text(trip.status.displayName)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            DetailRow(label: "Vehicle Type", value: trip.vehicleType)
                        }
                        .padding(.top, 8)
                    }

                    GroupBox(label: Text("Timing").font(.headline)) {
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(label: "Date", value: trip.date)
                            DetailRow(label: "Time", value: trip.time)
                            DetailRow(label: "Start Time", value: format(date: trip.startTime))
                            if let endTime = trip.endTime {
                                DetailRow(label: "End Time", value: format(date: endTime))
                            }
                        }
                        .padding(.top, 8)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if let passengers = trip.passengers {
                            DetailRow(label: "Passengers", value: "\(passengers)")
                        }

                        if let weight = trip.loadWeight {
                            DetailRow(label: "Load Weight", value: "\(weight) kg")
                        }
                    }

                    if trip.status == .inProgress || trip.status == .delayed {
                        VStack(spacing: 16) {
                            Button(action: {
                                isUpdating = true
                                viewModel.updateTripStatus(tripId: trip.id, status: .completed) { error in
                                    isUpdating = false
                                    if error == nil {
                                        dismiss() // Close the view on success
                                    } else {
                                        showErrorAlert = true
                                    }
                                }
                            }) {
                                if isUpdating {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isColorBlindMode ? Color(hex: "E69F00") : Color.green)
                                        .cornerRadius(12)
                                } else {
                                    Text("Mark as Completed")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isColorBlindMode ? Color(hex: "E69F00") : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(isUpdating)

                            Button(action: {
                                isUpdating = true
                                viewModel.updateTripStatus(tripId: trip.id, status: .cancelled) { error in
                                    isUpdating = false
                                    if error == nil {
                                        dismiss() // Close the view on success
                                    } else {
                                        showErrorAlert = true
                                    }
                                }
                            }) {
                                if isUpdating {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isColorBlindMode ? Color(hex: "E69F00") : Color.red)
                                        .cornerRadius(12)
                                } else {
                                    Text("Cancel Trip")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isColorBlindMode ? Color(hex: "E69F00") : Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(isUpdating)
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error ?? "An error occurred while updating the trip status."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                viewModel.fetchDriverName(by: trip.driverId)
                viewModel.fetchVehicleInfo(by: trip.vehicleId)
            }
        }
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Helper View
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview
#Preview {
    // Preview now uses the renamed view
    return AllTripsView()
}
