import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseDatabaseInternal

// MARK: - Model
struct Vehicle: Identifiable, Codable, Equatable {
    let id: UUID
    var make: String
    var model: String
    var year: String
    var vin: String
    var licensePlate: String
    var vehicleType: VehicleType
    var status: VehicleStatus
    var assignedDriverId: UUID? // Nullable to indicate unassigned or assigned driver
    var passengerCapacity: Int? // For car, van, and bus
    var cargoCapacity: Double? // For truck in kg
}

enum VehicleType: String, CaseIterable, Identifiable, Codable {
    case car = "Car"
    case truck = "Truck"
    case van = "Van"
    case bus = "Bus"

    var id: String { self.rawValue }
    
    var requiresPassengerCapacity: Bool {
        return self == .car || self == .van || self == .bus
    }
    
    var requiresCargoCapacity: Bool {
        return self == .truck
    }
}

enum VehicleStatus: String, CaseIterable, Identifiable, Codable {
    case active = "Active"
    case inMaintenance = "In Maintenance"
    case deactivated = "Deactivated"

    var id: String { self.rawValue }
}

// MARK: - ViewModel
class VehicleManagerViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var searchText: String = ""
    @Published var recentlyDeleted: Vehicle?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var typeFilter: VehicleType? = nil
    @Published var statusFilter: VehicleStatus? = nil
    @Published var activeFilters: [String] = []
    @Published var selectedVehicle: Vehicle? = nil
    
    private var db = Firestore.firestore()
    
    init() {
        fetchVehicles()
    }
    
    var filteredVehicles: [Vehicle] {
        let filtered = vehicles.filter { vehicle in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
            vehicle.make.lowercased().contains(searchText.lowercased()) ||
            vehicle.model.lowercased().contains(searchText.lowercased()) ||
            vehicle.licensePlate.lowercased().contains(searchText.lowercased()) ||
            vehicle.vin.lowercased().contains(searchText.lowercased())
            
            // Type filter
            let matchesType = typeFilter == nil || vehicle.vehicleType == typeFilter!
            
            // Status filter
            let matchesStatus = statusFilter == nil || vehicle.status == statusFilter!
            
            return matchesSearch && matchesType && matchesStatus
        }
        
        // Sort by make
        return filtered.sorted { $0.make < $1.make }
    }
    
    func updateActiveFilters() {
        activeFilters.removeAll()
        
        if typeFilter != nil {
            activeFilters.append("Type: \(typeFilter!.rawValue)")
        }
        
        if statusFilter != nil {
            activeFilters.append("Status: \(statusFilter!.rawValue)")
        }
    }
    
    func fetchVehicles() {
        isLoading = true
        print("Fetching vehicles from Firestore...")

        db.collection("vehicles").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            defer { self.isLoading = false }

            if let error = error {
                self.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                print(self.errorMessage!)
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No documents found.")
                return
            }

            print("Number of vehicles fetched: \(documents.count)")

            var loadedVehicles: [Vehicle] = []

            for document in documents {
                let data = document.data()

                guard
                    let idString = data["id"] as? String,
                    let id = UUID(uuidString: idString),
                    let make = data["make"] as? String,
                    let model = data["model"] as? String,
                    let year = data["year"] as? String,
                    let vin = data["vin"] as? String,
                    let licensePlate = data["licensePlate"] as? String,
                    let vehicleTypeString = data["vehicleType"] as? String,
                    let vehicleType = VehicleType(rawValue: vehicleTypeString),
                    let statusString = data["status"] as? String,
                    let status = VehicleStatus(rawValue: statusString)
                else {
                    print("Skipping document due to missing fields: \(document.documentID)")
                    continue
                }
                
                // Parse optional fields
                let assignedDriverIdString = data["assignedDriverId"] as? String
                let assignedDriverId = assignedDriverIdString != nil ? UUID(uuidString: assignedDriverIdString!) : nil
                let passengerCapacity = data["passengerCapacity"] as? Int
                let cargoCapacity = data["cargoCapacity"] as? Double

                let vehicle = Vehicle(
                    id: id,
                    make: make,
                    model: model,
                    year: year,
                    vin: vin,
                    licensePlate: licensePlate,
                    vehicleType: vehicleType,
                    status: status,
                    assignedDriverId: assignedDriverId,
                    passengerCapacity: passengerCapacity,
                    cargoCapacity: cargoCapacity
                )

                loadedVehicles.append(vehicle)
                print("Loaded vehicle: \(make) \(model), VIN: \(vin)")
            }

            DispatchQueue.main.async {
                self.vehicles = loadedVehicles
                print("Vehicles successfully loaded: \(self.vehicles.count)")
            }
        }
    }

    private func saveVehicleToFirestore(_ vehicle: Vehicle, completion: @escaping (Bool) -> Void) {
        print("Saving vehicle with VIN: \(vehicle.vin)")
        
        let vehicleData: [String: Any] = [
            "id": vehicle.id.uuidString,
            "make": vehicle.make,
            "model": vehicle.model,
            "year": vehicle.year,
            "vin": vehicle.vin,
            "licensePlate": vehicle.licensePlate,
            "vehicleType": vehicle.vehicleType.rawValue,
            "status": vehicle.status.rawValue,
            "assignedDriverId": vehicle.assignedDriverId?.uuidString ?? NSNull(),
            "passengerCapacity": vehicle.passengerCapacity ?? NSNull(),
            "cargoCapacity": vehicle.cargoCapacity ?? NSNull()
        ]

        db.collection("vehicles").document(vehicle.id.uuidString).setData(vehicleData) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                self.errorMessage = "Error saving vehicle: \(error.localizedDescription)"
                print("Firebase error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("Vehicle successfully saved to Firestore with ID: \(vehicle.id.uuidString)")
            completion(true)
        }
    }
    
    private func deleteVehicleFromFirestore(vehicleId: UUID) {
        isLoading = true
        
        db.collection("vehicles").document(vehicleId.uuidString).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error deleting vehicle: \(error.localizedDescription)"
                print("Delete error: \(error.localizedDescription)")
                return
            }
            
            print("Vehicle successfully deleted from Firestore")
            
            if let index = self.vehicles.firstIndex(where: { $0.id == vehicleId }) {
                self.recentlyDeleted = self.vehicles.remove(at: index)
                print("Vehicle removed from local array")
            }
        }
    }
    
    private func deleteVehicleFromRealtimeDB(vehicleId: UUID) {
        let db = Database.database().reference()
        let vehicleRef = db.child("vehicles").child(vehicleId.uuidString)

        vehicleRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting vehicle from Realtime DB: \(error.localizedDescription)")
            } else {
                print("Vehicle deleted from Realtime DB successfully.")
            }
        }
    }
    
    func delete(vehicle: Vehicle) {
        deleteVehicleFromFirestore(vehicleId: vehicle.id)
        deleteVehicleFromRealtimeDB(vehicleId: vehicle.id)
    }
    
    func undoDelete() {
        guard let vehicle = recentlyDeleted else { return }
        
        isLoading = true
        
        saveVehicleToFirestore(vehicle) { [weak self] success in
            guard let self = self else { return }
            self.isLoading = false
            
            if success {
                self.vehicles.append(vehicle)
                self.recentlyDeleted = nil
            }
        }
    }
    
    func add(vehicle: Vehicle) {
        saveVehicleToFirestore(vehicle) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                DispatchQueue.main.async {
                    self.vehicles.append(vehicle)
                    print("Added new vehicle to local array: \(vehicle.make) \(vehicle.model)")
                }
            }
        }
    }
    
    func update(vehicle: Vehicle) {
        saveVehicleToFirestore(vehicle) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                DispatchQueue.main.async {
                    if let index = self.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                        self.vehicles[index] = vehicle
                        print("Updated vehicle in local array at index \(index)")
                    } else {
                        self.vehicles.append(vehicle)
                        print("Added updated vehicle to local array")
                    }
                }
            }
        }
    }
    
    func refreshVehicles() {
        fetchVehicles()
    }
}

// MARK: - Placeholder View
struct VehiclePlaceholderView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.2.fill")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 10)

            Text("No Vehicles Added")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Add vehicles to manage your fleet efficiently. Tap the button below to get started.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onCreate) {
                Text("Add Vehicle")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                .padding()
        )
    }
}

// MARK: - Main View
struct VehicleManagementView: View {
    @StateObject private var viewModel = VehicleManagerViewModel()
    @State private var showingAddVehicle = false
    @State private var editingVehicle: Vehicle?
    @State private var showingDeleteConfirmation = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showingContextMenu = false
    @State private var showingError = false
    @State private var showingFilters = false
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    // Computed properties for colors
    private var primaryColor: Color {
        isColorBlindMode ? .cbBlue : .blue
    }
    
    private var accentColor: Color {
        isColorBlindMode ? .cbOrange : .red
    }
    
    private var statusActiveColor: Color {
        isColorBlindMode ? .cbBlue : .green
    }
    
    private var statusMaintenanceColor: Color {
        isColorBlindMode ? .cbOrange : .orange
    }
    
    private var secondaryColor: Color {
        isColorBlindMode ? .cbBlue : .gray
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredVehicles.isEmpty {
                    emptyStateView
                } else {
                    vehiclesListView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vehicle Management")
            .toolbar {
                if !viewModel.isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddVehicle = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(primaryColor)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.title3)
                                .foregroundColor(primaryColor)
                                .overlay(alignment: .topTrailing) {
                                    if !viewModel.activeFilters.isEmpty {
                                        Circle()
                                            .fill(accentColor)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .sheet(isPresented: $showingAddVehicle) {
                VehicleFormView(viewModel: viewModel, editingVehicle: nil)
            }
            .sheet(item: $editingVehicle) { vehicle in
                VehicleFormView(viewModel: viewModel, editingVehicle: vehicle)
            }
            .sheet(item: $viewModel.selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle)
            }
            .confirmationDialog("Filter Options", isPresented: $showingFilters) {
                Button("All Types") {
                    viewModel.typeFilter = nil
                    viewModel.updateActiveFilters()
                }
                ForEach(VehicleType.allCases) { type in
                    Button(type.rawValue) {
                        viewModel.typeFilter = type
                        viewModel.updateActiveFilters()
                    }
                }
                
                Divider()
                
                Button("All Statuses") {
                    viewModel.statusFilter = nil
                    viewModel.updateActiveFilters()
                }
                ForEach(VehicleStatus.allCases) { status in
                    Button(status.rawValue) {
                        viewModel.statusFilter = status
                        viewModel.updateActiveFilters()
                    }
                }
                
                Divider()
                
                Button("Reset All Filters") {
                    viewModel.typeFilter = nil
                    viewModel.statusFilter = nil
                    viewModel.updateActiveFilters()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if !viewModel.activeFilters.isEmpty {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.activeFilters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(primaryColor.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            viewModel.typeFilter = nil
                            viewModel.statusFilter = nil
                            viewModel.updateActiveFilters()
                        } label: {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(primaryColor)
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.activeFilters)
                }
            }
            .overlay(alignment: .bottom) {
                if let _ = viewModel.recentlyDeleted {
                    UndoToastV {
                        viewModel.undoDelete()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.recentlyDeleted)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Vehicle?"),
                    message: Text("Are you sure you want to delete this vehicle? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let vehicleToDelete = vehicleToDelete {
                            withAnimation {
                                viewModel.delete(vehicle: vehicleToDelete)
                            }
                        }
                        vehicleToDelete = nil
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
                viewModel.fetchVehicles()
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if errorMessage != nil {
                    showingError = true
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading vehicles...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 50))
                .foregroundColor(secondaryColor.opacity(0.6))

            Text(viewModel.searchText.isEmpty ? "No Vehicles Found" : "No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(viewModel.searchText.isEmpty ?
                "Tap the button below to add a new vehicle." :
                "No vehicles match your search criteria.")
                .font(.subheadline)
                .foregroundColor(secondaryColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if viewModel.searchText.isEmpty {
                Button(action: {
                    showingAddVehicle = true
                }) {
                    Text("Add Vehicle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(primaryColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
                .padding(.horizontal, 40)
            }
        }
        .padding()
    }

    private var vehiclesListView: some View {
        List {
            ForEach(viewModel.filteredVehicles) { vehicle in
                VehicleCard(vehicle: vehicle)
                    .swipeActions(edge: .leading) {
                        Button {
                            var updated = vehicle
                            updated.status = .active
                            viewModel.update(vehicle: updated)
                        } label: {
                            Label("Active", systemImage: "car.fill")
                        }
                        .tint(statusActiveColor)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            var updated = vehicle
                            updated.status = .inMaintenance
                            viewModel.update(vehicle: updated)
                        } label: {
                            Label("In Maintenance", systemImage: "wrench.fill")
                        }
                        .tint(statusMaintenanceColor)
                    }
                    .contextMenu {
                        Button("Edit") { editingVehicle = vehicle }
                        Button("Delete", role: .destructive) {
                            vehicleToDelete = vehicle
                            showingDeleteConfirmation = true
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedVehicle = vehicle
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchVehicles()
        }
    }
}

// MARK: - Vehicle Detail View
struct VehicleDetailView: View {
    let vehicle: Vehicle
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    private var statusColor: Color {
        switch vehicle.status {
        case .deactivated:
            return isColorBlindMode ? .cbOrange : .red
        case .inMaintenance:
            return isColorBlindMode ? .cbOrange : .orange
        case .active:
            return isColorBlindMode ? .cbBlue : .green
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vehicle Information")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRowV(label: "Make", value: vehicle.make)
                        DetailRowV(label: "Model", value: vehicle.model)
                        DetailRowV(label: "Year", value: vehicle.year)
                        DetailRowV(label: "Type", value: vehicle.vehicleType.rawValue)
                        DetailRowV(label: "Status", value: vehicle.status.rawValue)
                            .foregroundColor(statusColor)
                        
                        if vehicle.vehicleType.requiresPassengerCapacity, let capacity = vehicle.passengerCapacity {
                            DetailRowV(label: "Passenger Capacity", value: "\(capacity) passengers")
                        }
                        
                        if vehicle.vehicleType.requiresCargoCapacity, let capacity = vehicle.cargoCapacity {
                            DetailRowV(label: "Cargo Capacity", value: "\(Int(capacity)) kg")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Identification Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Identification")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRowV(label: "VIN", value: vehicle.vin)
                        DetailRowV(label: "License Plate", value: vehicle.licensePlate)
                        DetailRowV(label: "Assigned Driver",
                                 value: vehicle.assignedDriverId?.uuidString ?? "Not assigned")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("\(vehicle.make) \(vehicle.model)")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .onChange(of: isColorBlindMode) { newValue in
                print("VehicleDetailView isColorBlindMode changed to: \(newValue)")
            }
        }
    }
}

struct DetailRowV: View {
    let label: String
    let value: String
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    private var secondaryColor: Color {
        isColorBlindMode ? .cbBlue : .gray
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(secondaryColor)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .onChange(of: isColorBlindMode) { newValue in
            print("DetailRowV isColorBlindMode changed to: \(newValue)")
        }
    }
}

// MARK: - Card View
struct VehicleCard: View {
    var vehicle: Vehicle
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    private var statusColor: Color {
        switch vehicle.status {
        case .deactivated:
            return isColorBlindMode ? .cbOrange : .red
        case .inMaintenance:
            return isColorBlindMode ? .cbOrange : .orange
        case .active:
            return isColorBlindMode ? .cbBlue : .green
        }
    }

    private var primaryColor: Color {
        isColorBlindMode ? .cbBlue : .blue
    }

    private var secondaryColor: Color {
        isColorBlindMode ? .cbBlue : .secondary
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(statusColor)
                        .font(.system(size: 26))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vehicle.make) \(vehicle.model)")
                            .font(.title3.bold())
                        Text("\(vehicle.year) • \(vehicle.vehicleType.rawValue)")
                            .font(.subheadline)
                        Text(vehicle.licensePlate)
                            .font(.subheadline)
                            .foregroundColor(secondaryColor)
                        HStack {
                            Text(vehicle.status.rawValue)
                                .font(.subheadline)
                                .foregroundColor(statusColor)
                            
                            if vehicle.assignedDriverId != nil {
                                Text("Assigned")
                                    .font(.subheadline)
                                    .foregroundColor(primaryColor)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
        }
        .onChange(of: isColorBlindMode) { newValue in
            print("VehicleCard isColorBlindMode changed to: \(newValue)")
        }
    }
}

// MARK: - Form View
struct VehicleFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VehicleManagerViewModel
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var vehicleType: VehicleType = .car
    @State private var status: VehicleStatus = .active
    @State private var showAlert = false
    @State private var isLoading = false
    @State private var passengerCapacity: Int = 4
    @State private var cargoCapacity: Double = 1000.0

    var editingVehicle: Vehicle?

    private var secondaryColor: Color {
        isColorBlindMode ? .cbBlue : .secondary
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle Details")) {
                    TextField("Make", text: $make)
                        .textInputAutocapitalization(.words)
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.words)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                    Picker("Vehicle Type", selection: $vehicleType) {
                        ForEach(VehicleType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("Status", selection: $status) {
                        ForEach(VehicleStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if vehicleType.requiresPassengerCapacity {
                    Section(header: Text("Passenger Capacity")) {
                        Stepper("Passengers: \(passengerCapacity)", value: $passengerCapacity, in: 1...50)
                    }
                }
                
                if vehicleType.requiresCargoCapacity {
                    Section(header: Text("Cargo Capacity")) {
                        HStack {
                            TextField("Weight", value: $cargoCapacity, format: .number)
                                .keyboardType(.decimalPad)
                            Text("kg")
                                .foregroundColor(secondaryColor)
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Please fill in all required fields"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle(editingVehicle == nil ? "Add Vehicle" : "Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            if isFormValid {
                                saveVehicle()
                            } else {
                                showAlert = true
                            }
                        }
                    }
                }
            }
            .onAppear {
                if let vehicle = editingVehicle {
                    make = vehicle.make
                    model = vehicle.model
                    year = vehicle.year
                    vin = vehicle.vin
                    licensePlate = vehicle.licensePlate
                    vehicleType = vehicle.vehicleType
                    status = vehicle.status
                    passengerCapacity = vehicle.passengerCapacity ?? 4
                    cargoCapacity = vehicle.cargoCapacity ?? 1000.0
                }
            }
            .onChange(of: isColorBlindMode) { newValue in
                print("VehicleFormView isColorBlindMode changed to: \(newValue)")
            }
        }
    }
    
    private var isFormValid: Bool {
        !make.isEmpty &&
        !model.isEmpty &&
        !year.isEmpty &&
        !vin.isEmpty &&
        !licensePlate.isEmpty &&
        (vehicleType.requiresPassengerCapacity ? passengerCapacity > 0 : true) &&
        (vehicleType.requiresCargoCapacity ? cargoCapacity > 0 : true)
    }
    
    private func saveVehicle() {
        isLoading = true
        
        let vehicle = Vehicle(
            id: editingVehicle?.id ?? UUID(),
            make: make,
            model: model,
            year: year,
            vin: vin,
            licensePlate: licensePlate,
            vehicleType: vehicleType,
            status: status,
            assignedDriverId: editingVehicle?.assignedDriverId,
            passengerCapacity: vehicleType.requiresPassengerCapacity ? passengerCapacity : nil,
            cargoCapacity: vehicleType.requiresCargoCapacity ? cargoCapacity : nil
        )
        
        if editingVehicle == nil {
            viewModel.add(vehicle: vehicle)
        } else {
            viewModel.update(vehicle: vehicle)
        }
        
        dismiss()
    }
}

// MARK: - Undo Toast
struct UndoToastV: View {
    var undoAction: () -> Void
    @State private var isVisible = true
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    private var primaryColor: Color {
        isColorBlindMode ? .cbBlue : .blue
    }

    var body: some View {
        if isVisible {
            HStack {
                Text("Vehicle deleted")
                Spacer()
                Button("Undo", action: undoAction)
                    .foregroundColor(primaryColor)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
            .onChange(of: isColorBlindMode) { newValue in
                print("UndoToastV isColorBlindMode changed to: \(newValue)")
            }
        }
    }
}

#Preview {
    VehicleManagementView()
}
