import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Task Model
struct MaintenanceTask: Identifiable, Codable {
    let id: String
    let vehicleId: String
    let issue: String
    let completionDate: String // Changed to String for simpler date format
    let priority: String
    let assignedToId: String // Changed to store personnel ID
    let status: TaskStatus
    let createdAt: String // Changed to String for simpler date format
    
    enum TaskStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

// MARK: - ViewModel
class AssignTaskViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var maintenancePersonnel: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        fetchVehicles()
        fetchMaintenancePersonnel()
    }
    
    func fetchVehicles() {
        isLoading = true
        db.collection("vehicles")
            .whereField("status", isEqualTo: VehicleStatus.active.rawValue)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching vehicles: \(error.localizedDescription)"
                    return
                }
                
                // Parse the documents manually to ensure proper handling of UUID fields
                self.vehicles = snapshot?.documents.compactMap { document in
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
                    else { return nil }
                    
                    // Parse optional fields
                    let assignedDriverIdString = data["assignedDriverId"] as? String
                    let assignedDriverId = assignedDriverIdString != nil ? UUID(uuidString: assignedDriverIdString!) : nil
                    let passengerCapacity = data["passengerCapacity"] as? Int
                    let cargoCapacity = data["cargoCapacity"] as? Double
                    
                    return Vehicle(
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
                } ?? []
            }
    }
    
    func fetchMaintenancePersonnel() {
        isLoading = true
        db.collection("users")
            .whereField("role", isEqualTo: "maintenance")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching maintenance personnel: \(error.localizedDescription)"
                    return
                }
                
                self.maintenancePersonnel = snapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
            }
    }
    
    func assignTask(vehicleId: String, issue: String, completionDate: Date, priority: String, assignedToId: String, completion: @escaping (Bool) -> Void) {
        // Format dates as strings in yyyy-MM-dd format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let task = MaintenanceTask(
            id: UUID().uuidString,
            vehicleId: vehicleId,
            issue: issue,
            completionDate: dateFormatter.string(from: completionDate),
            priority: priority,
            assignedToId: assignedToId,
            status: .pending,
            createdAt: dateFormatter.string(from: Date())
        )
        
        do {
            try db.collection("maintenance_tasks").document(task.id).setData(from: task) { error in
                if let error = error {
                    self.errorMessage = "Error assigning task: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                completion(true)
            }
        } catch {
            self.errorMessage = "Error creating task: \(error.localizedDescription)"
            completion(false)
        }
    }
}

struct AssignTaskView: View {
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var selectedVehicle: String = ""
    @State private var selectedVehicleId: String = ""
    @State private var selectedIssue: String = "Engine Overheating"
    @State private var showOtherIssue: Bool = false
    @State private var otherIssueDescription: String = ""
    @State private var completionDate = Date()
    @State private var priority: String = "Medium"
    @State private var selectedPersonnel: String = ""
    @State private var selectedPersonnelId: String = ""
    @State private var showVehicleSheet = false
    @State private var showPersonnelSheet = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showingConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    let genericIssues = ["Engine Overheating", "Brake Failure", "Tire Puncture", "Oil Leak", "Other"]
    let priorities = ["High", "Medium", "Low"]
    
    private var minimumDate: Date {
        return Date()
    }
    
    private func validateFields() -> Bool {
        if selectedVehicle.isEmpty {
            validationMessage = "Please select a vehicle"
            return false
        }
        if selectedIssue.isEmpty {
            validationMessage = "Please select an issue type"
            return false
        }
        if showOtherIssue && otherIssueDescription.isEmpty {
            validationMessage = "Please provide a description for the other issue"
            return false
        }
        if selectedPersonnel.isEmpty {
            validationMessage = "Please select maintenance personnel"
            return false
        }
        return true
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6).opacity(0.8), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 10) {
                    Form {
                        Section(header: Text("Task Details").font(.caption).foregroundColor(.gray)) {
                            HStack {
                                Text("Vehicle")
                                Spacer()
                                Button(action: { showVehicleSheet = true }) {
                                    Text(selectedVehicle.isEmpty ? "Select Vehicle" : selectedVehicle)
                                        .foregroundColor(selectedVehicle.isEmpty ? .gray : .blue)
                                }
                            }
                            
                            Picker("Issue", selection: $selectedIssue) {
                                ForEach(genericIssues, id: \.self) { issue in
                                    Text(issue).tag(issue)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedIssue) { newValue in
                                withAnimation {
                                    showOtherIssue = (newValue == "Other")
                                }
                            }
                            
                            if showOtherIssue {
                                TextField("Other Issue Description", text: $otherIssueDescription)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            DatePicker("Expected Completion Date", selection: $completionDate, in: minimumDate..., displayedComponents: [.date])
                                .datePickerStyle(.compact)
                            
                            Picker("Priority", selection: $priority) {
                                ForEach(priorities, id: \.self) { priority in
                                    Text(priority).tag(priority)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            HStack {
                                Text("Maintenance Personnel")
                                Spacer()
                                Button(action: { showPersonnelSheet = true }) {
                                    Text(selectedPersonnel.isEmpty ? "Select Personnel" : selectedPersonnel)
                                        .foregroundColor(selectedPersonnel.isEmpty ? .gray : .blue)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    Button(action: {
                        if validateFields() {
                            showingConfirmation = true
                        } else {
                            showValidationAlert = true
                        }
                    }) {
                        Text("Assign")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Assign Task")
            .sheet(isPresented: $showVehicleSheet) {
                VehicleListView(selectedVehicle: $selectedVehicle, selectedVehicleId: $selectedVehicleId)
            }
            .sheet(isPresented: $showPersonnelSheet) {
                PersonnelListView(selectedPersonnel: $selectedPersonnel, selectedPersonnelId: $selectedPersonnelId)
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
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
                                let issue = showOtherIssue ? otherIssueDescription : selectedIssue
                                viewModel.assignTask(
                                    vehicleId: selectedVehicleId,
                                    issue: issue,
                                    completionDate: completionDate,
                                    priority: priority,
                                    assignedToId: selectedPersonnelId
                                ) { success in
                                    if success {
                                        dismiss()
                                    }
                                }
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
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct VehicleListView: View {
    @Binding var selectedVehicle: String
    @Binding var selectedVehicleId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AssignTaskViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.vehicles) { vehicle in
                    Button(action: {
                        selectedVehicle = vehicle.licensePlate
                        selectedVehicleId = vehicle.id.uuidString
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text(vehicle.licensePlate)
                                    .font(.headline)
                                Text("\(vehicle.make) \(vehicle.model)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Vehicles")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct PersonnelListView: View {
    @Binding var selectedPersonnel: String
    @Binding var selectedPersonnelId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AssignTaskViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.maintenancePersonnel) { person in
                    Button(action: {
                        selectedPersonnel = person.name
                        selectedPersonnelId = person.id
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text(person.name)
                                    .font(.headline)
                                Text(person.phone)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Personnel")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView()
    }
}
