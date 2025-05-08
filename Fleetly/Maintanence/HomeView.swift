import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct HomeView: View {
    @State private var maintenanceTasks: [MaintenanceTask]
    @State private var vehicles: [String: Vehicle]
    @State private var userName: String
    @State private var showCardAnimation = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastTaskId: String?
    @State private var selectedFilter: TaskFilter = .all // State for filter
    @StateObject private var colorManager = ColorManager.shared
    
    private let db = Firestore.firestore()
    
    // Enum for filter options
    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var id: String { self.rawValue }
    }
    
    // Filtered tasks based on selected filter
    var filteredTasks: [MaintenanceTask] {
        switch selectedFilter {
        case .all:
            return maintenanceTasks
        case .pending:
            return maintenanceTasks.filter { $0.status == .pending }
        case .inProgress:
            return maintenanceTasks.filter { $0.status == .inProgress }
        case .completed:
            return maintenanceTasks.filter { $0.status == .completed }
        case .cancelled:
            return maintenanceTasks.filter { $0.status == .cancelled }
        }
    }
    
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
    
    // Initializer to allow setting initial state for previews
    init(
        maintenanceTasks: [MaintenanceTask] = [],
        vehicles: [String: Vehicle] = [:],
        userName: String = "User"
    ) {
        self._maintenanceTasks = State(initialValue: maintenanceTasks)
        self._vehicles = State(initialValue: vehicles)
        self._userName = State(initialValue: userName)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overview Section
                    VStack(alignment: .leading, spacing: 12) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardGridView(
                                icon: "car.fill",
                                title: "Total Vehicles",
                                value: "19",
                                color: colorManager.primaryColor
                            )
                            
                            StatCardGridView(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Pending Tasks",
                                value: "\(maintenanceTasks.filter { $0.status == .pending }.count)",
                                color: colorManager.accentColor
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Assigned Work Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Assigned Work")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Filter Icon with Menu
                            Menu {
                                ForEach(TaskFilter.allCases) { filter in
                                    Button(action: {
                                        selectedFilter = filter
                                    }) {
                                        HStack {
                                            Text(filter.rawValue)
                                            if selectedFilter == filter {
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(colorManager.primaryColor)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(colorManager.primaryColor)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                    )
                            }
                            .accessibilityLabel("Filter tasks")
                        }
                        .padding(.horizontal, 16)
                        
                        if isLoading {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(colorManager.accentColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if filteredTasks.isEmpty {
                            VStack {
                                Spacer()
                                Text(selectedFilter == .all ? "No Assignments" : "No \(selectedFilter.rawValue) Tasks")
                                    .font(.system(.title3, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    
                                    .padding(.horizontal, 24)
                                Spacer()
                            }
                        } else {
                            ForEach($maintenanceTasks, id: \.id) { $task in
                                if filteredTasks.contains(where: { $0.id == task.id }) {
                                    WorkOrderCard(
                                        task: $task,
                                        vehicle: vehicles[task.vehicleId] ?? Self.fallbackVehicle,
                                        onStatusChange: { newStatus in
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                task.status = newStatus
                                                if newStatus == .completed {
                                                    if let index = maintenanceTasks.firstIndex(where: { $0.id == task.id }) {
                                                        maintenanceTasks.remove(at: index)
                                                        updateTaskStatusInFirestore(taskId: task.id, newStatus: newStatus)
                                                    }
                                                } else {
                                                    updateTaskStatusInFirestore(taskId: task.id, newStatus: newStatus)
                                                }
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
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Hi, \(userName)")
                        .font(.headline.weight(.bold)) // Matches iOS inline title style
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Present ProfileView as a sheet
                        let profileView = ProfileView()
                        let hostingController = UIHostingController(rootView: profileView)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(hostingController, animated: true)
                        }
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24, weight: .regular, design: .rounded))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(colorManager.primaryColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profile")
                }
            }
            .navigationBarTitleDisplayMode(.inline) // Inline title mode to match screenshot
            .onAppear {
                withAnimation {
                    showCardAnimation = true
                    fetchUserName()
                    fetchTasks()
                }
                requestNotificationPermission()
                setupTaskListener()
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
        db.collection("maintenance_tasks").document(taskId).updateData([
            "status": newStatus.rawValue
        ]) { error in
            if let error = error {
                print("UpdateTaskStatus: Error updating task \(taskId): \(error.localizedDescription)")
            } else {
                print("UpdateTaskStatus: Successfully updated task \(taskId) to status \(newStatus.rawValue)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupTaskListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("maintenance_tasks")
            .whereField("assignedToId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to tasks: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let newTasks = documents.compactMap { doc -> MaintenanceTask? in
                    try? doc.data(as: MaintenanceTask.self)
                }
                
                // Check for new tasks
                if let lastTaskId = lastTaskId {
                    let newAssignedTasks = newTasks.filter { task in
                        task.id != lastTaskId && task.status == .pending
                    }
                    
                    for task in newAssignedTasks {
                        scheduleNotification(for: task)
                    }
                }
                
                // Update lastTaskId with the most recent task
                if let mostRecentTask = newTasks.max(by: { $0.createdAt < $1.createdAt }) {
                    lastTaskId = mostRecentTask.id
                }
                
                // Update the tasks list
                maintenanceTasks = newTasks
                
                // Fetch vehicle details for new tasks
                fetchVehicles(for: newTasks)
            }
    }
    
    private func scheduleNotification(for task: MaintenanceTask) {
        let content = UNMutableNotificationContent()
        content.title = "New Maintenance Task Assigned"
        content.body = "Task: \(task.issue)\nPriority: \(task.priority)\nDue: \(task.completionDate)"
        content.sound = .default
        
        // Create a unique identifier for this notification
        let identifier = "task-\(task.id)"
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
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
                .fill(Color(.systemGray6))
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
    @State private var showingCompletionView: Bool = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Task ID and Vehicle Info
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task #\(task.id.prefix(8))")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text("\(vehicle.make) \(vehicle.model)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Priority Badge
                HStack(spacing: 4) {
                    Image(systemName: priorityIcon(task.priority))
                        .imageScale(.small)
                    Text(task.priority.capitalized)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor(task.priority).opacity(0.15))
                .foregroundStyle(priorityColor(task.priority))
                .clipShape(Capsule())
            }
            
            Divider()
                .background(Color.secondary.opacity(0.2))
            
            // Task Details
            VStack(alignment: .leading, spacing: 12) {
                // Issue Description
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(task.issue)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                
                // Due Date
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("Due: \(task.completionDate)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Status Badge
            HStack(spacing: 6) {
                Image(systemName: statusIcon(task.status))
                    .imageScale(.small)
                Text(task.status.rawValue.capitalized)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor(task.status).opacity(0.15))
            .foregroundStyle(statusColor(task.status))
            .clipShape(Capsule())
            
            // Action Slider
            GeometryReader { geometry in
                VStack(spacing: 8) {
                    Text(swipeActionText(task.status))
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(swipeActionColor(task.status))
                    
                    ZStack(alignment: .leading) {
                        // Background Track
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 56)
                        
                        // Progress Track
                        RoundedRectangle(cornerRadius: 12)
                            .fill(swipeActionColor(task.status).opacity(showAnimation ? 0.5 : 0.3))
                            .frame(width: max(0, dragOffset), height: 56)
                        
                        // Slider Knob
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 48, height: 48)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: swipeActionIcon(task.status))
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(showAnimation ? swipeActionColor(task.status) : .gray)
                                .scaleEffect(showAnimation ? 1.2 : 1.0)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let maxWidth = geometry.size.width - 48
                                    dragOffset = min(max(value.translation.width, 0), maxWidth)
                                    showAnimation = dragOffset >= maxWidth * 0.6
                                    #if !targetEnvironment(simulator)
                                    if showAnimation {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                    #endif
                                }
                                .onEnded { value in
                                    let maxWidth = geometry.size.width - 48
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if dragOffset >= maxWidth * 0.6 {
                                            handleSwipeAction()
                                            #if !targetEnvironment(simulator)
                                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                                            impact.impactOccurred()
                                            #endif
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
            .frame(height: 100)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
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
        case .completed: return Color(hex: "E69F00")
        case .inProgress: return Color(hex: "E69F00")
        case .pending: return Color(hex: "E69F00")
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
        case "low": return Color(hex: "E69F00")
        case "medium": return Color(hex: "E69F00")
        case "high": return Color(hex: "E69F00")
        default: return Color(hex: "E69F00")
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
        case .pending: return Color(hex: "0072B2")
        case .inProgress: return Color(hex: "0072B2")
        case .completed: return Color(hex: "E69F00")
        case .cancelled: return .gray
        }
    }
    
    private func handleSwipeAction() {
        switch task.status {
        case .pending:
            onStatusChange(.inProgress)
        case .inProgress:
            showingCompletionView = true // Show the sheet before marking as completed
        case .completed, .cancelled:
            onStatusChange(.completed) // Adjust as needed for your workflow
        }
    }
    
    private func storeMaintenanceCosts(taskId: String, cost: Inventory.MaintenanceCost) {
        let costsRef = db.collection("maintenance_tasks").document(taskId).collection("costs")
        
        do {
            try costsRef.document(cost.id).setData(from: cost) { error in
                if let error = error {
                    print("Error storing maintenance costs: \(error.localizedDescription)")
                    errorMessage = "Failed to store maintenance costs"
                } else {
                    onStatusChange(.completed) // Mark as completed after saving costs
                }
            }
        } catch {
            print("Error encoding maintenance cost: \(error.localizedDescription)")
            errorMessage = "Failed to encode maintenance costs"
        }
    }
}
