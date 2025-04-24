import SwiftUI
import FirebaseDatabaseInternal
import FirebaseFirestore

// MARK: - Model
struct Vehicle: Identifiable, Codable, Equatable{
    let id: UUID
    var make: String
    var model: String
    var year: String
    var vin: String
    var licensePlate: String
    var vehicleType: VehicleType
    var status: VehicleStatus
    var assignedDriverId: UUID? // Nullable to indicate unassigned or assigned driver
}

enum VehicleType: String, CaseIterable, Identifiable, Codable{
    case car = "Car"
    case truck = "Truck"
    case van = "Van"
    case bus = "Bus"

    var id: String { self.rawValue }
}

enum VehicleStatus: String, CaseIterable, Identifiable, Codable{
    case active = "Active"
    case inMaintenance = "In Maintenance"
    case deactivated = "Deactivated"

    var id: String { self.rawValue }
}

func saveVehicleToFirestore(_ vehicle: Vehicle) {
    let db = Firestore.firestore()

    // Convert Vehicle to a dictionary
    let vehicleData: [String: Any] = [
        "id": vehicle.id.uuidString,
        "make": vehicle.make,
        "model": vehicle.model,
        "year": vehicle.year,
        "vin": vehicle.vin,
        "licensePlate": vehicle.licensePlate,
        "vehicleType": vehicle.vehicleType.rawValue,
        "status": vehicle.status.rawValue,
        "assignedDriverId": vehicle.assignedDriverId?.uuidString ?? NSNull()
    ]

    db.collection("vehicles").document(vehicle.id.uuidString).setData(vehicleData) { error in
        if let error = error {
            print("Error saving vehicle: \(error.localizedDescription)")
        } else {
            print("Vehicle saved successfully.")
        }
    }
}

func deleteVehicleFromFirestore(vehicleId: UUID) {
    let db = Firestore.firestore()
    db.collection("vehicles").document(vehicleId.uuidString).delete { error in
        if let error = error {
            print("Error deleting vehicle from Firestore: \(error.localizedDescription)")
        } else {
            print("Vehicle deleted from Firestore successfully.")
        }
    }
}

func deleteVehicleFromRealtimeDB(vehicleId: UUID) {
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
                    .background(Color.white)
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

// MARK: - ViewModel
class VehicleManagerViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [Driver] // Reference to existing drivers
    @Published var searchText: String = ""
    @Published var sortAscending: Bool = true
    @Published var recentlyDeleted: Vehicle?
    @Published var selectedDriver: Driver? // For assignment

    var filteredVehicles: [Vehicle] {
        let filtered = vehicles.filter {
            searchText.isEmpty || "\($0.make) \($0.model)".lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted {
            sortAscending ? $0.make < $1.make : $0.make > $1.make
        }
    }

    init(drivers: [Driver] = []) {
        self.drivers = drivers
    }

    func delete(vehicle: Vehicle) {
        if let index = vehicles.firstIndex(of: vehicle) {
            recentlyDeleted = vehicles.remove(at: index)
            deleteVehicleFromFirestore(vehicleId: vehicle.id) // Delete from Firestore
            deleteVehicleFromRealtimeDB(vehicleId: vehicle.id) // Also delete from Realtime DB
        }
    }

    func undoDelete() {
        if let vehicle = recentlyDeleted {
            vehicles.append(vehicle)
            saveVehicleToFirestore(vehicle) // Re-save to Firestore when undoing delete
            recentlyDeleted = nil
        }
    }

    func add(vehicle: Vehicle) {
        vehicles.append(vehicle)
        saveVehicleToFirestore(vehicle) // Save to Firestore on add
    }

    func update(vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
            saveVehicleToFirestore(vehicle) // Save to Firestore on update
        }
    }
    
    func fetchVehiclesFromFirestore() {
          let db = Firestore.firestore()
        db.collection("vehicles").getDocuments { (snapshot, error) in
             if let error = error {
                    print("Error fetching vehicles: \(error.localizedDescription)")
                    return
               }
                guard let documents = snapshot?.documents else {
                    print("No vehicles found")
                    return
                }
                self.vehicles = documents.compactMap { doc -> Vehicle? in
                    do {
                        let data = try doc.data(as: Vehicle.self)
                        return data
                    } catch {
                        print("Error decoding vehicle: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
        }
    
    func loadVehicles() {
        fetchVehiclesFromFirestore()
    }
}

// MARK: - Main View
import SwiftUI

struct VehicleManagementView: View {
    @StateObject private var viewModel = VehicleManagerViewModel()
    @State private var showingAddVehicle = false
    @State private var editingVehicle: Vehicle? = nil
    @State private var showingAssignDriver = false
    @State private var showingDeleteConfirmation = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showingContextMenu = false
    @State private var selectedVehicle: Vehicle?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.filteredVehicles.isEmpty {
                    VehiclePlaceholderView {
                        showingAddVehicle = true
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredVehicles) { vehicle in
                            VehicleCard(vehicle: vehicle)
                                .onTapGesture {
                                    selectedVehicle = vehicle
                                }
                                .onLongPressGesture {
                                    selectedVehicle = vehicle
                                    showingContextMenu = true
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .confirmationDialog(
                                    "Vehicle Options",
                                    isPresented: $showingContextMenu,
                                    presenting: selectedVehicle
                                ) { vehicle in
                                    Button("Edit") {
                                        editingVehicle = vehicle
                                    }
                                    
                                    Button("Delete", role: .destructive) {
                                        vehicleToDelete = vehicle
                                        showingDeleteConfirmation = true
                                    }
                                    
                                    Button("Cancel", role: .cancel) {}
                                } message: { vehicle in
                                    Text("\(vehicle.make) \(vehicle.model)")
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vehicle Management")
            .toolbar {
                if !viewModel.filteredVehicles.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddVehicle = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddVehicle) {
                VehicleFormView(viewModel: viewModel, editingVehicle: nil)
            }
            .sheet(item: $editingVehicle) { vehicle in
                VehicleFormView(viewModel: viewModel, editingVehicle: vehicle)
            }
            .sheet(isPresented: $showingAssignDriver) {
                if let vehicle = editingVehicle {
                    AssignDriverView(viewModel: viewModel, vehicle: vehicle)
                }
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
            .overlay(alignment: .bottom) {
                if let _ = viewModel.recentlyDeleted {
                    UndoToast {
                        viewModel.undoDelete()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.recentlyDeleted)
                }
            }
            .onAppear {
                let driverVM = DriverManagerViewModel()
                viewModel.drivers = driverVM.drivers
                viewModel.loadVehicles() // Fetch vehicles from Firestore
            }
        }
    }
}

// MARK: - Card View
struct VehicleCard: View {
    var vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vehicle.make) \(vehicle.model) (\(vehicle.year))")
                        .font(.title3.bold())
                    Text("Plate: \(vehicle.licensePlate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Status: \(vehicle.status.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(vehicle.status == .deactivated ? .red : vehicle.status == .inMaintenance ? .orange : .green)
                    if let driverId = vehicle.assignedDriverId {
                        Text("Assigned to: Driver ID \(driverId.uuidString.prefix(8))...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unassigned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.vertical, 4)
    }
}

// MARK: - Form View
struct VehicleFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VehicleManagerViewModel

    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var vin = ""
    @State private var licensePlate = ""
    @State private var vehicleType: VehicleType = .car
    @State private var status: VehicleStatus = .active

    var editingVehicle: Vehicle?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle Info")) {
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Year", text: $year)
                        .keyboardType(.numberPad)
                    TextField("VIN", text: $vin)
                    TextField("License Plate", text: $licensePlate)
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
                    Button("Save") {
                        let vehicle = Vehicle(
                            id: editingVehicle?.id ?? UUID(),
                            make: make,
                            model: model,
                            year: year,
                            vin: vin,
                            licensePlate: licensePlate,
                            vehicleType: vehicleType,
                            status: status,
                            assignedDriverId: editingVehicle?.assignedDriverId
                        )
                        if editingVehicle == nil {
                            viewModel.add(vehicle: vehicle)
                        } else {
                            viewModel.update(vehicle: vehicle)
                        }

                        dismiss()
                    }
                    .disabled(make.isEmpty || model.isEmpty || year.isEmpty || vin.isEmpty || licensePlate.isEmpty)
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
                }
            }
        }
    }
}

// MARK: - Assign Driver View
struct AssignDriverView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VehicleManagerViewModel
    var vehicle: Vehicle?

    @State private var selectedDriverId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Assign Driver")) {
                    Picker("Select Driver", selection: $selectedDriverId) {
                        Text("Unassign").tag(nil as UUID?) // Explicitly tag with nil
                        ForEach(viewModel.drivers) { driver in
                            Text(driver.name).tag(driver.id as UUID?) // Match the optional type
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
}
// MARK: - Undo Toast
struct UndoToast: View {
    var undoAction: () -> Void
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack {
                Text("Vehicle deleted")
                Spacer()
                Button("Undo", action: undoAction)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}

//hellooo

#Preview {
    VehicleManagementView()
}
