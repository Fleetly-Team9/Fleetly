import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore

// MARK: - Trip Model
struct Trip: Identifiable, Codable {
    let id: String
    let driverId: String
    let vehicleId: String
    let startLocation: String
    let endLocation: String
    let date: String
    let time: String
    let startTime: Date
    var endTime: Date?
    let status: TripStatus
    let vehicleType: String
    let passengers: Int?
    let loadWeight: Double?
    
    enum TripStatus: String, Codable {
        case assigned = "assigned"
        case ongoing = "ongoing"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

// MARK: - ViewModel
class AssignTripViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        fetchVehicles()
        fetchDrivers()
    }
    
    func fetchVehicles() {
        isLoading = true
        
        db.collection("vehicles")
            .whereField("status", isEqualTo: "Active")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                defer { self.isLoading = false }
                
                if let error = error {
                    self.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
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
                    else { continue }
                    
                    let assignedDriverIdString = data["assignedDriverId"] as? String
                    let assignedDriverId = assignedDriverIdString != nil ? UUID(uuidString: assignedDriverIdString!) : nil
                    
                    let vehicle = Vehicle(
                        id: id,
                        make: make,
                        model: model,
                        year: year,
                        vin: vin,
                        licensePlate: licensePlate,
                        vehicleType: vehicleType,
                        status: status,
                        assignedDriverId: assignedDriverId
                    )
                    
                    loadedVehicles.append(vehicle)
                }
                
                DispatchQueue.main.async {
                    self.vehicles = loadedVehicles
                }
            }
    }
    
    func fetchDrivers() {
        isLoading = true
        
        db.collection("users")
            .whereField("role", isEqualTo: "driver")
            .whereField("isApproved", isEqualTo: true)
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                defer { self.isLoading = false }
                
                if let error = error {
                    self.errorMessage = "Error fetching drivers: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                var loadedDrivers: [User] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard
                        let name = data["name"] as? String,
                        let email = data["email"] as? String,
                        let phone = data["phone"] as? String,
                        let role = data["role"] as? String
                    else { continue }
                    
                    let gender = data["gender"] as? String
                    let age = data["age"] as? Int
                    let disability = data["disability"] as? String
                    let aadharNumber = data["aadharNumber"] as? String
                    let drivingLicenseNumber = data["drivingLicenseNumber"] as? String
                    let aadharDocUrl = data["aadharDocUrl"] as? String
                    let licenseDocUrl = data["licenseDocUrl"] as? String
                    let isApproved = data["isApproved"] as? Bool ?? true
                    let isAvailable = data["isAvailable"] as? Bool ?? true
                    
                    let user = User(
                        id: document.documentID,
                        name: name,
                        email: email,
                        phone: phone,
                        role: role,
                        gender: gender,
                        age: age,
                        disability: disability,
                        aadharNumber: aadharNumber,
                        drivingLicenseNumber: drivingLicenseNumber,
                        aadharDocUrl: aadharDocUrl,
                        licenseDocUrl: licenseDocUrl,
                        isApproved: isApproved,
                        isAvailable: isAvailable
                    )
                    
                    loadedDrivers.append(user)
                }
                
                DispatchQueue.main.async {
                    self.drivers = loadedDrivers
                }
            }
    }
    
     func createTrip(
        driverId: String,
        vehicleId: String,
        startLocation: String,
        endLocation: String,
        date: String,
        time: String,
        startTime: Date,
        vehicleType: String,
        passengers: Int?,
        loadWeight: Double?,
        completion: @escaping (Bool) -> Void
    ) {
        let tripId = UUID().uuidString
        let trip = Trip(
            id: tripId,
            driverId: driverId,
            vehicleId: vehicleId,
            startLocation: startLocation,
            endLocation: endLocation,
            date: date,
            time: time,
            startTime: startTime,
            status: .assigned,
            vehicleType: vehicleType,
            passengers: passengers,
            loadWeight: loadWeight
        )
        
        do {
            try db.collection("trips").document(tripId).setData(from: trip) { [weak self] error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    self.errorMessage = "Error creating trip: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                // Update vehicle's assigned status
                self.updateVehicleAssignment(vehicleId: vehicleId, driverId: driverId) { success in
                    completion(success)
                }
            }
        } catch {
            self.errorMessage = "Error encoding trip data: \(error.localizedDescription)"
            completion(false)
        }
    }
    
    private func updateVehicleAssignment(vehicleId: String, driverId: String, completion: @escaping (Bool) -> Void) {
        let vehicleData: [String: Any] = [
            "assignedDriverId": driverId
        ]
        
        db.collection("vehicles").document(vehicleId).updateData(vehicleData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error updating vehicle assignment: \(error.localizedDescription)"
                completion(false)
                return
            }
            completion(true)
        }
    }
}

// MARK: - ClearableTextField
struct ClearableTextField: View {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(placeholder, text: $text, onCommit: onCommit)
                .padding(.trailing, 24)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
    }
}

// MARK: - AssignView
struct AssignView: View {
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @ObservedObject var viewModel = LocationSearchViewModel()
    @State private var journeyDate = Date()
    @State private var passengers = 1
    @State private var loadWeight = 0.0
    @State private var selectedVehicleType: VehicleType = .passenger
    @State private var selectedVehicle: Vehicle?
    @State private var showVehicleSheet = false
    @State private var showDriverSheet = false
    @State private var selectedDriver: User?
    @State private var journeyTime = Date()
    @FocusState private var fromFieldFocused: Bool
    @FocusState private var toFieldFocused: Bool
    @StateObject private var assignViewModel = AssignTripViewModel()
    @State private var showingError = false
    @State private var isAssigning = false
    @State private var showingConfirmation = false
    
    enum VehicleType: String, CaseIterable {
        case passenger = "Passenger Vehicle"
        case cargo = "Cargo Vehicle"
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Journey Details").font(.headline)) {
                    // From Location
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        ClearableTextField(text: $fromLocation, placeholder: "From Location")
                            .focused($fromFieldFocused)
                            .onChange(of: fromLocation) { newValue in
                                viewModel.searchForLocations(newValue, isFrom: true)
                            }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Suggestions for From Location
                    if !viewModel.fromSearchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.fromSearchResults, id: \.self) { result in
                                Button(action: {
                                    viewModel.selectLocation(result, isPickup: true)
                                    fromLocation = "\(result.title), \(result.subtitle)"
                                    viewModel.fromSearchResults = []
                                    fromFieldFocused = false
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.blue)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        VStack(alignment: .leading) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Select \(result.title), \(result.subtitle)")
                                
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.fromSearchResults.isEmpty)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // To Location
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        ClearableTextField(text: $toLocation, placeholder: "To Location")
                            .focused($toFieldFocused)
                            .onChange(of: toLocation) { newValue in
                                viewModel.searchForLocations(newValue, isFrom: false)
                            }
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Suggestions for To Location
                    if !viewModel.toSearchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.toSearchResults, id: \.self) { result in
                                Button(action: {
                                    viewModel.selectLocation(result, isPickup: false)
                                    toLocation = "\(result.title), \(result.subtitle)"
                                    viewModel.toSearchResults = []
                                    toFieldFocused = false
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.green)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        VStack(alignment: .leading) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("Select \(result.title), \(result.subtitle)")
                                
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .animation(.easeInOut(duration: 0.25), value: viewModel.toSearchResults.isEmpty)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Date of Journey
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        DatePicker(
                            "Date of Journey",
                            selection: $journeyDate,
                            in: Date()..., // Restrict to today and future dates
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    
                    // Time of Journey
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        DatePicker(
                            "Time of Journey",
                            selection: $journeyTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section(header: Text("Vehicle Type").font(.headline)) {
                    Picker("Vehicle Type", selection: $selectedVehicleType) {
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if selectedVehicleType == .passenger {
                    Section(header: Text("Passengers").font(.subheadline)) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Stepper(value: $passengers, in: 1...10) {
                                Text("Passengers: \(passengers)")
                            }
                        }
                    }
                } else {
                    Section(header: Text("Load Details").font(.subheadline)) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            TextField("Weight", value: $loadWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text("kg")
                        }
                    }
                }
                
                Section(header: Text("Assignments").font(.headline)) {
                    // Vehicle Selection Card
                    Button(action: { showVehicleSheet = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vehicle")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let vehicle = selectedVehicle {
                                    Text("\(vehicle.make) \(vehicle.model)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(vehicle.licensePlate)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not Assigned")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Driver Selection Card
                    Button(action: { showDriverSheet = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Driver")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let driver = selectedDriver {
                                    Text(driver.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(driver.phone)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not Assigned")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isAssigning {
                        ProgressView()
                    } else {
                        Button(action: { showingConfirmation = true }) {
                            Text("Assign")
                                .foregroundColor(.blue)
                                .font(.system(size: 17))
                        }
                        .disabled(selectedVehicle == nil || selectedDriver == nil || fromLocation.isEmpty || toLocation.isEmpty)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    assignViewModel.errorMessage = nil
                }
            } message: {
                Text(assignViewModel.errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showingConfirmation) {
                NavigationStack {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Confirm Assignment")
                            .font(.title2.bold())
                        
                        HStack(spacing: 20) {
                            Button {
                                showingConfirmation = false
                            } label: {
                                Text("Cancel")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                showingConfirmation = false
                                assignTrip()
                            } label: {
                                Text("Confirm")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showVehicleSheet) {
                VehicleListView(selectedVehicle: $selectedVehicle, vehicles: assignViewModel.vehicles)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
            .sheet(isPresented: $showDriverSheet) {
                DriverListView(selectedDriver: $selectedDriver, drivers: assignViewModel.drivers)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
        }
    }
    
    private func assignTrip() {
        guard let vehicle = selectedVehicle,
              let driver = selectedDriver else {
            return
        }
        
        isAssigning = true
        
        // Format date and time in ISO 8601
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: journeyDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: journeyTime)
        
        // Combine date and time for startTime
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: journeyDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: journeyTime)
        
        guard let startTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                          minute: timeComponents.minute ?? 0,
                                          second: 0,
                                          of: journeyDate) else {
            isAssigning = false
            return
        }
        
        assignViewModel.createTrip(
            driverId: driver.id,
            vehicleId: vehicle.id.uuidString,
            startLocation: fromLocation,
            endLocation: toLocation,
            date: dateString,
            time: timeString,
            startTime: startTime,
            vehicleType: selectedVehicleType.rawValue,
            passengers: selectedVehicleType == .passenger ? passengers : nil,
            loadWeight: selectedVehicleType == .cargo ? loadWeight : nil
        ) { success in
            isAssigning = false
            if success {
                dismiss()
            } else {
                showingError = true
            }
        }
    }
}

// MARK: - VehicleListView
struct VehicleListView: View {
    @Binding var selectedVehicle: Vehicle?
    let vehicles: [Vehicle]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vehicles) { vehicle in
                    Button(action: {
                        selectedVehicle = vehicle
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(vehicle.make) \(vehicle.model)")
                                    .font(.headline)
                                Text(vehicle.licensePlate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Vehicle")
        }
    }
}

// MARK: - DriverListView
struct DriverListView: View {
    @Binding var selectedDriver: User?
    let drivers: [User]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(drivers) { driver in
                    Button(action: {
                        selectedDriver = driver
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(driver.name)
                                    .font(.headline)
                                Text(driver.phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Driver")
        }
    }
}
