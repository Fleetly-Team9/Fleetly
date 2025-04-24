import SwiftUI

// MARK: - Model
struct Vehicle: Identifiable, Equatable {
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

enum VehicleType: String, CaseIterable, Identifiable {
    case car = "Car"
    case truck = "Truck"
    case van = "Van"
    case bus = "Bus"
    
    var id: String { self.rawValue }
}

enum VehicleStatus: String, CaseIterable, Identifiable {
    case active = "Active"
    case inMaintenance = "In Maintenance"
    case deactivated = "Deactivated"
    
    var id: String { self.rawValue }
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
        }
    }

    func undoDelete() {
        if let vehicle = recentlyDeleted {
            vehicles.append(vehicle)
            recentlyDeleted = nil
        }
    }

    func add(vehicle: Vehicle) {
        vehicles.append(vehicle)
    }

    func update(vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
        }
    }

    func assignVehicle(to driver: Driver, vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            var updatedVehicle = vehicle
            updatedVehicle.assignedDriverId = driver.id
            vehicles[index] = updatedVehicle
        }
    }

    func unassignVehicle(vehicle: Vehicle) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            var updatedVehicle = vehicle
            updatedVehicle.assignedDriverId = nil
            vehicles[index] = updatedVehicle
        }
    }
}

// MARK: - Main View
import SwiftUI

struct VehicleManagementView: View {
    @StateObject private var viewModel = VehicleManagerViewModel()
    @State private var showingAddVehicle = false
    @State private var editingVehicle: Vehicle? = nil
    @State private var showingAssignDriver = false

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
                            VehicleCard(vehicle: vehicle) {
                                withAnimation {
                                    viewModel.delete(vehicle: vehicle)
                                }
                            }
                            .onTapGesture {
                                editingVehicle = vehicle
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.delete(vehicle: vehicle)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    editingVehicle = vehicle
                                    showingAssignDriver = true
                                } label: {
                                    Label("Assign", systemImage: "person.fill")
                                }
                                .tint(.blue)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
            }
        }
    }
}

// MARK: - Card View
struct VehicleCard: View {
    var vehicle: Vehicle
    var onDelete: () -> Void

    @State private var offsetX: CGFloat = 0
    @GestureState private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background delete button (on the right)
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(.trailing)
                .opacity(offsetX < -100 ? 1 : 0)
            }

            // Foreground card
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
            .offset(x: offsetX)
            .padding(.vertical, 4)
            .gesture(
                DragGesture()
                    .updating($isDragging) { value, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        offsetX = min(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width < -100 {
                            withAnimation {
                                onDelete()
                            }
                        } else {
                            withAnimation {
                                offsetX = 0
                            }
                        }
                    }
            )
        }
        .animation(.spring(), value: offsetX)
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
                                    Text("Unassign").tag(nil as UUID?)
                                    ForEach(viewModel.drivers) { driver in
                                        Text("\(driver.firstName) \(driver.lastName)")
                                            .tag(driver.id as UUID?)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
            .navigationTitle("Assign Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let vehicle = vehicle, let driverId = selectedDriverId {
                            if driverId == nil {
                                viewModel.unassignVehicle(vehicle: vehicle)
                            } else {
                                if let driver = viewModel.drivers.first(where: { $0.id == driverId }) {
                                    viewModel.assignVehicle(to: driver, vehicle: vehicle)
                                }
                            }
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedDriverId = vehicle?.assignedDriverId
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

#Preview {
    VehicleManagementView()
}
