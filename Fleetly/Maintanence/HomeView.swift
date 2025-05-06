import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var maintenanceTasks: [MaintenanceTask] = []
    @State private var vehicles: [String: Vehicle] = [:] // Maps vehicleId to Vehicle
    @State private var userName: String = "User"
    @State private var showCardAnimation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    // Fallback Vehicle to simplify ForEach expression
    private static let fallbackVehicle = Vehicle(
        id: UUID(),
        make: "Unknown",
        model: "Unknown",
        year: "",
        vin: "",
        licensePlate: "",
        vehicleType: .car, // Default, adjust based on VehicleType
        status: .active, // Default, adjust based on VehicleStatus
        assignedDriverId: nil,
        passengerCapacity: nil,
        cargoCapacity: nil
    )
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome, \(userName)!")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("Your tasks for today")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 44, height: 44)
                                        .shadow(radius: 4)
                                )
                        }
                        .accessibilityLabel("Profile")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Overview Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
                            OverviewStat(icon: "car.fill", title: "Total Vehicles", value: "19", color: Color.blue)
                            OverviewStat(icon: "wrench.and.screwdriver.fill", title: "Pending  Tasks", value: "\(maintenanceTasks.count)", color: Color.orange)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Assigned Work Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Work")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if maintenanceTasks.isEmpty {
                            VStack {
                                Spacer()
                                Text("No Assignments")
                                    .font(.system(.title3, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.background)
                                            .overlay(.ultraThinMaterial)
                                            .shadow(radius: 2)
                                    )
                                    .padding(.horizontal, 24)
                                Spacer()
                            }
                        } else {
                            ForEach($maintenanceTasks, id: \.id) { $task in
                                WorkOrderCard(
                                    task: $task,
                                    vehicle: vehicles[task.vehicleId] ?? Self.fallbackVehicle,
                                    onStatusChange: { newStatus in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            task.status = newStatus
                                            if newStatus == .completed {
                                                if let index = maintenanceTasks.firstIndex(where: { $0.id == task.id }) {
                                                    maintenanceTasks.remove(at: index)
                                                }
                                            }
                                            updateTaskStatusInFirestore(taskId: task.id, newStatus: newStatus)
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                                .opacity(showCardAnimation ? 1 : 0)
                                .offset(y: showCardAnimation ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.5).delay(Double(maintenanceTasks.firstIndex(where: { $0.id == task.id }) ?? 0) * 0.1),
                                    value: showCardAnimation
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation {
                    showCardAnimation = true
                    fetchUserName()
                    fetchTasks()
                }
            }
        }
    }
    
    private func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("FetchUserName: No user is logged in")
            userName = "Guest"
            return
        }
        
        print("FetchUserName: Fetching name for userId: \(userId)")
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("FetchUserName: Error fetching user document: \(error.localizedDescription)")
                userName = Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "User"
                return
            }
            
            guard let document = document, document.exists, let data = document.data(), let name = data["name"] as? String else {
                print("FetchUserName: User document not found or missing name field")
                userName = Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? "User"
                return
            }
            
            print("FetchUserName: Successfully fetched name: \(name)")
            userName = name
        }
    }
    
    private func fetchTasks() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("FetchTasks: No user is logged in")
            errorMessage = "User not logged in"
            return
        }
        
        print("FetchTasks: Fetching all tasks for userId: \(userId)")
        isLoading = true
        errorMessage = nil
        
        db.collection("maintenance_tasks")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    print("FetchTasks: Error fetching tasks: \(error.localizedDescription)")
                    errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("FetchTasks: No documents found")
                    errorMessage = "No tasks found"
                    return
                }
                
                print("FetchTasks: Found \(documents.count) documents")
                for doc in documents {
                    print("FetchTasks: Document ID: \(doc.documentID), Data: \(doc.data())")
                }
                
                maintenanceTasks = documents.compactMap { doc in
                    do {
                        let task = try doc.data(as: MaintenanceTask.self)
                        print("FetchTasks: Successfully decoded task: \(task)")
                        return task
                    } catch {
                        print("FetchTasks: Failed to decode document \(doc.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }.filter { $0.assignedToId == userId }
                
                print("FetchTasks: Filtered to \(maintenanceTasks.count) tasks for userId: \(userId)")
                if maintenanceTasks.isEmpty {
                    errorMessage = "No tasks assigned to you"
                } else {
                    fetchVehicles(for: maintenanceTasks)
                }
            }
    }
    
    private func fetchVehicles(for tasks: [MaintenanceTask]) {
        let vehicleIds = Set(tasks.map { $0.vehicleId })
        print("FetchVehicles: Fetching data for \(vehicleIds.count) unique vehicle IDs: \(vehicleIds)")
        
        for vehicleId in vehicleIds {
            db.collection("vehicles").document(vehicleId).getDocument { document, error in
                if let error = error {
                    print("FetchVehicles: Error fetching vehicle \(vehicleId): \(error.localizedDescription)")
                    vehicles[vehicleId] = Self.fallbackVehicle
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    print("FetchVehicles: Vehicle document \(vehicleId) not found")
                    vehicles[vehicleId] = Self.fallbackVehicle
                    return
                }
                
                do {
                    // Manually decode to handle UUID
                    guard let make = data["make"] as? String,
                          let model = data["model"] as? String,
                          let year = data["year"] as? String,
                          let vin = data["vin"] as? String,
                          let licensePlate = data["licensePlate"] as? String,
                          let vehicleTypeRaw = data["vehicleType"] as? String,
                          let statusRaw = data["status"] as? String else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing required fields"))
                    }
                    
                    // Assume vehicleType and status are enums with rawValues
                    guard let vehicleType = VehicleType(rawValue: vehicleTypeRaw),
                          let status = VehicleStatus(rawValue: statusRaw) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid vehicleType or status"))
                    }
                    
                    let assignedDriverId = data["assignedDriverId"] as? String
                    let passengerCapacity = data["passengerCapacity"] as? Int
                    let cargoCapacity = data["cargoCapacity"] as? Double
                    
                    // Convert document ID to UUID
                    guard let uuid = UUID(uuidString: vehicleId) else {
                        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid UUID for vehicleId: \(vehicleId)"))
                    }
                    
                    let vehicle = Vehicle(
                        id: uuid,
                        make: make,
                        model: model,
                        year: year,
                        vin: vin,
                        licensePlate: licensePlate,
                        vehicleType: vehicleType,
                        status: status,
                        assignedDriverId: assignedDriverId.flatMap { UUID(uuidString: $0) },
                        passengerCapacity: passengerCapacity,
                        cargoCapacity: cargoCapacity
                    )
                    
                    print("FetchVehicles: Successfully fetched vehicle: \(vehicle)")
                    vehicles[vehicleId] = vehicle
                } catch {
                    print("FetchVehicles: Failed to decode vehicle \(vehicleId): \(error.localizedDescription)")
                    vehicles[vehicleId] = Self.fallbackVehicle
                }
            }
        }
    }
    
    private func updateTaskStatusInFirestore(taskId: String, newStatus: MaintenanceTask.TaskStatus) {
        let taskRef = db.collection("maintenance_tasks").document(taskId)
        
        var updateData: [String: Any] = [
            "status": newStatus.rawValue
        ]
        
        if newStatus == .completed {
            updateData["completedAt"] = FieldValue.serverTimestamp()
        }
        
        taskRef.updateData(updateData) { error in
            if let error = error {
                print("Error updating task status: \(error.localizedDescription)")
                errorMessage = "Failed to update task status"
            }
        }
    }
    
    private func storeMaintenanceCosts(taskId: String, cost: Inventory.MaintenanceCost) {
        let costsRef = db.collection("maintenance_tasks").document(taskId).collection("costs")
        
        do {
            try costsRef.document(cost.id).setData(from: cost) { error in
                if let error = error {
                    print("Error storing maintenance costs: \(error.localizedDescription)")
                    errorMessage = "Failed to store maintenance costs"
                }
            }
        } catch {
            print("Error encoding maintenance cost: \(error.localizedDescription)")
            errorMessage = "Failed to encode maintenance costs"
        }
    }
}

struct OverviewStat: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: 24, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(radius: 2)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.primary)
                Text(title.uppercased())
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: (UIScreen.main.bounds.width - 48) / 2, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    LinearGradient(
                        colors: [color.opacity(0.05), color.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
}

struct WorkOrderCard: View {
    @Binding var task: MaintenanceTask
    let vehicle: Vehicle
    var onStatusChange: (MaintenanceTask.TaskStatus) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var showAnimation: Bool = false
    @State private var showingCompletionView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Task \(task.id)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(vehicle.make) \(vehicle.model)")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .background(Color.secondary.opacity(0.2))
            
            // Body
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.blue)
                        .imageScale(.medium)
                    Text(task.issue)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                }
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                        .imageScale(.medium)
                    Text("Due: \(task.completionDate)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Status and Priority
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: statusIcon(task.status))
                        .foregroundStyle(statusColor(task.status))
                        .imageScale(.small)
                    Text(task.status.rawValue.capitalized)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(statusColor(task.status))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(task.status).opacity(0.2))
                .clipShape(Capsule())
                
                HStack(spacing: 6) {
                    Image(systemName: priorityIcon(task.priority))
                        .foregroundStyle(priorityColor(task.priority))
                        .imageScale(.small)
                    Text(task.priority.capitalized)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(priorityColor(task.priority))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(priorityColor(task.priority).opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Action (All Swipable)
            GeometryReader { geometry in
                VStack(spacing: 12) {
                    Text(swipeActionText(task.status))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(swipeActionColor(task.status))
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 50)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(swipeActionColor(task.status).opacity(showAnimation ? 0.5 : 0.3))
                            .frame(width: max(0, dragOffset), height: 50)
                        
                        // Slider Knob
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 42, height: 42)
                                .shadow(radius: 2)
                            Image(systemName: swipeActionIcon(task.status))
                                .foregroundStyle(showAnimation ? swipeActionColor(task.status) : .gray)
                                .imageScale(.medium)
                                .scaleEffect(showAnimation ? 1.2 : 1.0)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let maxWidth = geometry.size.width - 42 // Account for knob width
                                    dragOffset = min(max(value.translation.width, 0), maxWidth)
                                    showAnimation = dragOffset >= maxWidth * 0.6
                                    if showAnimation {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                                .onEnded { value in
                                    let maxWidth = geometry.size.width - 42
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if dragOffset >= maxWidth * 0.6 {
                                            handleSwipeAction()
                                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                                            impact.impactOccurred()
                                        }
                                        dragOffset = 0
                                        showAnimation = false
                                    }
                                }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(swipeActionText(task.status)) for task \(task.id)")
                }
            }
            .frame(height: 86) // Fixed height to accommodate the slider and text
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .overlay(
                    LinearGradient(
                        colors: [.gray.opacity(0.03), .gray.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4, y: 2)
        )
        .sheet(isPresented: $showingCompletionView) {
            MaintenanceCompletionView(task: task)
        }
    }
    
    // Helper functions for status and priority
    private func statusIcon(_ status: MaintenanceTask.TaskStatus) -> String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "gearshape.fill"
        case .pending: return "hourglass"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private func statusColor(_ status: MaintenanceTask.TaskStatus) -> Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .orange
        case .pending: return .red
        case .cancelled: return .gray
        }
    }
    
    private func priorityIcon(_ priority: String) -> String {
        switch priority.lowercased() {
        case "low": return "arrow.down.circle"
        case "medium": return "arrow.right.circle"
        case "high": return "arrow.up.circle"
        default: return "arrow.down.circle"
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high": return .red
        default: return .green
        }
    }
    
    // Swipe Action Helpers
    private func swipeActionText(_ status: MaintenanceTask.TaskStatus) -> String {
        switch status {
        case .pending: return "Slide to Start"
        case .inProgress: return "Slide to Complete"
        case .completed: return "Slide to Archive"
        case .cancelled: return "Slide to Archive"
        }
    }
    
    private func swipeActionIcon(_ status: MaintenanceTask.TaskStatus) -> String {
        switch status {
        case .pending: return "wrench.fill"
        case .inProgress: return "checkmark.circle.fill"
        case .completed: return "archivebox.fill"
        case .cancelled: return "archivebox.fill"
        }
    }
    
    private func swipeActionColor(_ status: MaintenanceTask.TaskStatus) -> Color {
        switch status {
        case .pending: return .blue
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
    
    private func handleSwipeAction() {
        switch task.status {
        case .pending:
            onStatusChange(.inProgress)
        case .inProgress:
            showingCompletionView = true
        case .completed, .cancelled:
            onStatusChange(.completed) // Adjust as needed for your workflow
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
