import SwiftUI
import FirebaseFirestore

struct AssignTaskView: View {
    @State private var selectedVehicle: String = ""
    @State private var selectedIssue: String = ""
    @State private var showOtherIssue: Bool = false
    @State private var otherIssueDescription: String = ""
    @State private var completionDate = Date()
    @State private var completionTime = Date()
    @State private var priority: String = "Medium"
    @State private var selectedPersonnel: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var vehicles: [Vehicle] = []
    @State private var personnel: [String] = []
    
    let genericIssues = ["Engine Overheating", "Brake Failure", "Tire Puncture", "Oil Leak", "Battery Issue", "AC Problem", "Other"]
    let priorities = ["High", "Medium", "Low"]
    
    private let db = Firestore.firestore()
    
    // Define the minimum date and time (current date and time)
    private var minimumDate: Date {
        return Date()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6).opacity(0.8), Color(.systemBackground)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 10) {
                    Form {
                        Section(header: Text("TASK DETAILS").font(.caption).foregroundColor(.gray)) {
                            Picker("Vehicle", selection: $selectedVehicle) {
                                Text("Select Vehicle").tag("")
                                ForEach(vehicles, id: \.id) { vehicle in
                                    Text(vehicle.licensePlate).tag(vehicle.licensePlate)
                                }
                            }
                            .pickerStyle(.menu)
                            
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
                            
                            DatePicker("Expected Completion Time", selection: $completionTime, in: minimumDate..., displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.compact)
                            
                            Picker("Priority", selection: $priority) {
                                ForEach(priorities, id: \.self) { priority in
                                    Text(priority).tag(priority)
                                }
                            }
                            .pickerStyle(.menu)
                            
                            Picker("Maintenance Personnel", selection: $selectedPersonnel) {
                                Text("Select Personnel").tag("")
                                ForEach(personnel, id: \.self) { person in
                                    Text(person).tag(person)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    Button(action: assignTask) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Assign")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || selectedVehicle.isEmpty || selectedPersonnel.isEmpty || (selectedIssue.isEmpty && otherIssueDescription.isEmpty) || (showOtherIssue && otherIssueDescription.isEmpty))
                    .opacity(isLoading || selectedVehicle.isEmpty || selectedPersonnel.isEmpty || (selectedIssue.isEmpty && otherIssueDescription.isEmpty) || (showOtherIssue && otherIssueDescription.isEmpty) ? 0.5 : 1.0)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.large)
            .alert("Task Assignment", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                fetchVehicles()
                fetchPersonnel()
            }
        }
    }
    
    private func fetchVehicles() {
        db.collection("vehicles")
            .whereField("status", isEqualTo: VehicleStatus.active.rawValue)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching vehicles: \(error.localizedDescription)")
                    return
                }
                
                vehicles = snapshot?.documents.compactMap { document in
                    try? document.data(as: Vehicle.self)
                } ?? []
            }
    }
    
    private func fetchPersonnel() {
        db.collection("users")
            .whereField("role", isEqualTo: "maintenance")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching personnel: \(error.localizedDescription)")
                    return
                }
                
                personnel = snapshot?.documents.compactMap { document in
                    document.data()["name"] as? String
                } ?? []
            }
    }
    
    private func assignTask() {
        isLoading = true
        
        let issue = showOtherIssue ? otherIssueDescription : selectedIssue
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: completionTime)
        
        let workOrder = WorkOrder(
            id: Int.random(in: 1000...9999),
            vehicleNumber: selectedVehicle,
            issue: issue,
            status: "To be Done",
            expectedDelivery: timeString,
            priority: priorityValue(priority),
            parts: [],
            laborCost: nil,
            issues: [issue]
        )
        
        // Update vehicle status to in maintenance
        if let vehicle = vehicles.first(where: { $0.licensePlate == selectedVehicle }) {
            db.collection("vehicles").document(vehicle.id.uuidString).updateData([
                "status": VehicleStatus.inMaintenance.rawValue
            ]) { error in
                if let error = error {
                    print("Error updating vehicle status: \(error.localizedDescription)")
                    isLoading = false
                    alertMessage = "Failed to update vehicle status"
                    showAlert = true
                    return
                }
                
                // Create work order
                db.collection("workOrders").document(String(workOrder.id)).setData([
                    "id": workOrder.id,
                    "vehicleNumber": workOrder.vehicleNumber,
                    "issue": workOrder.issue,
                    "status": workOrder.status,
                    "expectedDelivery": workOrder.expectedDelivery,
                    "priority": workOrder.priority,
                    "parts": workOrder.parts,
                    "laborCost": workOrder.laborCost as Any,
                    "issues": workOrder.issues,
                    "assignedTo": selectedPersonnel,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { error in
                    isLoading = false
                    if let error = error {
                        print("Error creating work order: \(error.localizedDescription)")
                        alertMessage = "Failed to create work order"
                        showAlert = true
                    } else {
                        alertMessage = "Task assigned successfully"
                        showAlert = true
                        // Reset form
                        selectedVehicle = ""
                        selectedIssue = ""
                        showOtherIssue = false
                        otherIssueDescription = ""
                        completionDate = Date()
                        completionTime = Date()
                        priority = "Medium"
                        selectedPersonnel = ""
                    }
                }
            }
        }
    }
    
    private func priorityValue(_ priority: String) -> Int {
        switch priority {
        case "High": return 2
        case "Medium": return 1
        case "Low": return 0
        default: return 1
        }
    }
}

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView()
    }
}
