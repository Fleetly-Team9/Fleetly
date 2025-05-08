import SwiftUI
import Charts
import MapKit
import PhotosUI
import Firebase
import PDFKit

// Main Tab View
struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        TabView {
            DashboardHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            UserManagerView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Personnel")
                }

            VehicleManagementView()
                .tabItem {
                    Image(systemName: "car.2.fill")
                    Text("Vehicles")
                }
        }
    }
}


struct MaintenanceView: View {
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var showingNewTaskSheet = false
    @State private var selectedTask: MaintenanceTask?
    @State private var showingTaskDetail = false
    @State private var showingFilters = false
    @State private var selectedStatus: MaintenanceTask.TaskStatus?
    @State private var selectedPriority: String?
    @State private var selectedVehicle: String?
    @State private var dateRange: ClosedRange<Date> = Calendar.current.date(byAdding: .month, value: -1, to: Date())!...Date()
    
    var filteredTasks: [MaintenanceTask] {
        var filtered = viewModel.maintenanceTasks
        
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority.lowercased() == priority.lowercased() }
        }
        
        if let vehicle = selectedVehicle {
            filtered = filtered.filter { $0.vehicleId == vehicle }
        }
        
        // Filter by date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        filtered = filtered.filter { task in
            if let taskDate = dateFormatter.date(from: task.completionDate) {
                return dateRange.contains(taskDate)
            }
            return false
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stats Overview
                    HStack(spacing: 16) {
                        StatCardGridView(
                            icon: "wrench.fill",
                            title: "Pending Tasks",
                            value: "\(viewModel.pendingTasks)",
                            color: .orange
                        )
                        
                        StatCardGridView(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            value: "\(viewModel.completedTasks)",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if selectedStatus != nil || selectedPriority != nil || selectedVehicle != nil {
                                Button(action: {
                                    selectedStatus = nil
                                    selectedPriority = nil
                                    selectedVehicle = nil
                                }) {
                                    HStack {
                                        Text("Clear All")
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                                }
                            }
                            
                            if let status = selectedStatus {
                                FilterChip(
                                    title: status.rawValue.capitalized,
                                    color: .blue
                                ) {
                                    selectedStatus = nil
                                }
                            }
                            
                            if let priority = selectedPriority {
                                FilterChip(
                                    title: priority,
                                    color: priorityColor(priority)
                                ) {
                                    selectedPriority = nil
                                }
                            }
                            
                            if let vehicle = selectedVehicle {
                                FilterChip(
                                    title: vehicle,
                                    color: .purple
                                ) {
                                    selectedVehicle = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tasks List
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskCardView(task: task)
                                .onTapGesture {
                                    selectedTask = task
                                    showingTaskDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Maintenance Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewTaskSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                AssignTaskView()
            }
            .sheet(isPresented: $showingTaskDetail) {
                if let task = selectedTask {
                    TaskDetailView(task: task)
                }
            }
            .sheet(isPresented: $showingFilters) {
                FleetFilterView(
                    selectedStatus: $selectedStatus,
                    selectedPriority: $selectedPriority,
                    selectedVehicle: $selectedVehicle,
                    dateRange: $dateRange,
                    vehicles: viewModel.vehicles.map { $0.licensePlate }
                )
            }
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

struct TaskCardView: View {
    let task: MaintenanceTask
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var vehicleNumber: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicleNumber)
                        .font(.headline)
                    Text(task.issue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                ManagerStatusBadge(status: task.status)
            }
            
            HStack {
                ManagerPriorityBadge(priority: task.priority)
                
                Spacer()
                
                Text("Due: \(task.completionDate)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
        .onAppear {
            fetchVehicleNumber()
        }
    }
    
    private func fetchVehicleNumber() {
        let db = Firestore.firestore()
        db.collection("vehicles").document(task.vehicleId).getDocument { document, error in
            if let document = document,
               let data = document.data(),
               let licensePlate = data["licensePlate"] as? String {
                DispatchQueue.main.async {
                    self.vehicleNumber = licensePlate
                }
            }
        }
    }
}

struct ManagerStatusBadge: View {
    let status: MaintenanceTask.TaskStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct ManagerPriorityBadge: View {
    let priority: String
    
    var body: some View {
        Text(priority)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

struct TaskDetailView: View {
    let task: MaintenanceTask
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var showingStatusSheet = false
    @State private var selectedStatus: MaintenanceTask.TaskStatus?
    @State private var vehicleNumber: String = ""
    @State private var showingCompletionView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Task Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(title: "Vehicle", value: vehicleNumber)
                        InfoRow(title: "Issue", value: task.issue)
                        InfoRow(title: "Priority", value: task.priority)
                        InfoRow(title: "Status", value: task.status.rawValue.capitalized)
                        InfoRow(title: "Due Date", value: task.completionDate)
                        InfoRow(title: "Created", value: task.createdAt)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Action Button
                    Button(action: { showingStatusSheet = true }) {
                        Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Update Status", isPresented: $showingStatusSheet) {
                Button("Mark as Pending") {
                    updateStatus(.pending)
                }
                Button("Mark as In Progress") {
                    updateStatus(.inProgress)
                }
                Button("Mark as Completed") {
                    showingCompletionView = true
                }
                Button("Mark as Cancelled") {
                    updateStatus(.cancelled)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select new status for the task")
            }
            .sheet(isPresented: $showingCompletionView) {
                MaintenanceCompletionView(task: task)
            }
            .onAppear {
                fetchVehicleNumber()
            }
        }
    }
    
    private func updateStatus(_ newStatus: MaintenanceTask.TaskStatus) {
        viewModel.updateTaskStatus(taskId: task.id, newStatus: newStatus) { success in
            if success {
                dismiss()
            }
        }
    }
    
    private func fetchVehicleNumber() {
        let db = Firestore.firestore()
        db.collection("vehicles").document(task.vehicleId).getDocument { document, error in
            if let document = document,
               let data = document.data(),
               let licensePlate = data["licensePlate"] as? String {
                DispatchQueue.main.async {
                    self.vehicleNumber = licensePlate
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

struct TrackView: View {
    var body: some View {
        Text("Track View")
            .font(.title)
    }
}

class DriverStatsViewModel: ObservableObject {
    @Published var driverCount: Int = 0
    private let db = Firestore.firestore()

    func fetchDriverCount() {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching driver count: \(error.localizedDescription)")
                return
            }
            self.driverCount = querySnapshot?.documents.count ?? 0
        }
    }
}

// MARK: - Chart Data Models
struct VehicleStatusData: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
}

struct MaintenanceTaskData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

struct TripData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct ExpenseData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let date: Date
}

// MARK: - Chart Views
struct VehicleStatusChart: View {
    let data: [VehicleStatusData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vehicle Status Distribution")
                .font(.headline)
            
            Chart(data) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Status", item.status)
                )
                .foregroundStyle(by: .value("Status", item.status))
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MaintenanceTaskChart: View {
    let data: [MaintenanceTaskData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maintenance Tasks Overview")
                .font(.headline)
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.618),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", item.category))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TripTrendChart: View {
    let data: [TripData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trip Trends")
                .font(.headline)
            
            Chart(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Trips", item.count)
                )
                .foregroundStyle(.blue)
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Trips", item.count)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ExpenseChart: View {
    let data: [ExpenseData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expense Overview")
                .font(.headline)
            
            if data.isEmpty {
                VStack(spacing: 8) {
                    Text("No expense data available")
                        .foregroundColor(.gray)
                    Text("Add expenses to see the chart")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(.secondarySystemBackground))
            } else {
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Category", item.category),
                            y: .value("Amount", item.amount)
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                    }
                }
                .frame(height: 200)
                .chartForegroundStyleScale([
                    "Fuel": .blue,
                    "Toll": .orange,
                    "Miscellaneous": .purple,
                    "Parts": .red,
                    "Labor": .green
                ])
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// Add this before the DashboardHomeView struct
enum ChartType: String, CaseIterable {
    case vehicleStatus = "Vehicle Status"
    case maintenance = "Maintenance"
    case trips = "Trips"
    case expenses = "Expenses"
    
    var icon: String {
        switch self {
        case .vehicleStatus: return "car.2.fill"
        case .maintenance: return "wrench.fill"
        case .trips: return "map.fill"
        case .expenses: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .vehicleStatus: return .blue
        case .maintenance: return .orange
        case .trips: return .green
        case .expenses: return .purple
        }
    }
}

// Update DashboardHomeView to include expense data and chart
struct DashboardHomeView: View {
    @State private var showProfile = false
    @State private var selectedAction: ActionType?
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var viewModel = TripsViewModel()
    @StateObject private var driverCountViewModel = DriverStatsViewModel()
    
    // Add state for chart data
    @State private var vehicleStatusData: [VehicleStatusData] = []
    @State private var maintenanceTaskData: [MaintenanceTaskData] = []
    @State private var tripData: [TripData] = []
    
    // Add expense data state
    @State private var expenseData: [ExpenseData] = []
    
    // Add state for chart type selection
    @State private var selectedChart: ChartType = .vehicleStatus

    enum ActionType: Identifiable {
        case assign, maintain, track, reports
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Stat Cards Grid
                    let columns = [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ]

                    LazyVGrid(columns: columns, spacing: 10) {
                        NavigationLink(destination: LogbookView()){
                            StatCardGridView(
                                icon: "book.fill",
                                title: "Driver Logbook",
                                value: "\(driverCountViewModel.driverCount)",
                                color: .blue
                            )
                        }
                        .onAppear{
                            driverCountViewModel.fetchDriverCount()
                        }
                        NavigationLink(destination: AllTripsView()) { // Link to Active Trips
                            StatCardGridView(
                                icon: "location.fill",
                                title: "Overall Trips",
                                value: "\(viewModel.totalTrips)",
                                color: .teal
                            )
                        }
                        .onAppear{
                            viewModel.fetchTotalTrips()
                        }
                        NavigationLink(destination: MaintenanceView()) {
                            StatCardGridView(
                                icon: "wrench.fill",
                                title: "Maintenance",
                                value: "\(dashboardVM.pendingMaintenanceTasks)",
                                color: .red
                            )
                        }
                        NavigationLink(destination:TicketListView()){
                            StatCardGridView(
                                icon: "ticket.fill",
                                title: "Tickets",
                                value: "\(dashboardVM.activeTickets)",
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Quick Actions
                    VStack(alignment: .center, spacing: 8) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(spacing: 20) {
                            QuickActionButton(icon: "person.fill.badge.plus", title: "Assign")
                                .onTapGesture { selectedAction = .assign }

                            QuickActionButton(icon: "calendar.badge.clock", title: "Maintain")
                                .onTapGesture { selectedAction = .maintain }
                            QuickActionButton(icon: "doc.text.magnifyingglass", title: "Reports")
                                                           .onTapGesture { selectedAction = .reports }
                            QuickActionButton(icon: "map.fill", title: "Track")
                                .onTapGesture { selectedAction = .track }
                          
                        }
                    }
                    .sheet(item: $selectedAction) { action in
                        switch action {
                        case .reports:
                            ReportsView()
                        case .assign:
                            AssignView()
                        case .maintain:
                            AssignTaskView()
                        case .track:
                            TrackView()
                        }
                    }
                    .padding(.horizontal)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(30)
                    .shadow(color: Color(.label).opacity(0.08), radius: 4)
                    .padding(.horizontal)

                    // MARK: - Analytics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Chart Type Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ChartType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            selectedChart = type
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                            Text(type.rawValue)
                                                .font(.caption)
                                        }
                                        .frame(width: 100)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedChart == type ? type.color.opacity(0.2) : Color(.systemGray6))
                                        )
                                        .foregroundColor(selectedChart == type ? type.color : .gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Selected Chart View with animation
                        switch selectedChart {
                        case .vehicleStatus:
                            VehicleStatusChart(data: vehicleStatusData)
                                .padding(.horizontal)
                                .transition(.opacity)
                        case .maintenance:
                            MaintenanceTaskChart(data: maintenanceTaskData)
                                .padding(.horizontal)
                                .transition(.opacity)
                        case .trips:
                            TripTrendChart(data: tripData)
                                .padding(.horizontal)
                                .transition(.opacity)
                        case .expenses:
                            ExpenseChart(data: expenseData)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }

                    // MARK: - Analytics and Alerts
                    VStack(alignment: .leading, spacing: 16) {
                        // Alerts Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Alerts")
                                .font(.headline)

                            VStack(spacing: 12) {
                                AlertRowView(message: "Vehicle 23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle 45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(30)
                        .shadow(color: Color(.label).opacity(0.08), radius: 5)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hello, Fleet!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                showProfileView()
            }
            .onAppear {
                dashboardVM.fetchVehicleStats()
                fetchChartData()
                fetchExpenseData()
            }
        }
    }
    
    private func fetchChartData() {
        let db = Firestore.firestore()
        
        // Fetch Vehicle Status Data
        db.collection("vehicles").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let vehicles = documents.compactMap { try? $0.data(as: Vehicle.self) }
                let statusCounts = Dictionary(grouping: vehicles) { $0.status.rawValue }
                    .mapValues { $0.count }
                
                vehicleStatusData = statusCounts.map { VehicleStatusData(status: $0.key, count: $0.value) }
            }
        }
        
        // Fetch Maintenance Task Data
        db.collection("maintenance_tasks").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let tasks = documents.compactMap { try? $0.data(as: MaintenanceTask.self) }
                let statusCounts = Dictionary(grouping: tasks) { $0.status.rawValue }
                    .mapValues { $0.count }
                
                maintenanceTaskData = statusCounts.map { MaintenanceTaskData(category: $0.key, count: $0.value) }
            }
        }
        
        // Fetch Trip Data (last 7 days)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        db.collection("trips")
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let trips = documents.compactMap { try? $0.data(as: Ride.self) }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    let tripCounts = Dictionary(grouping: trips) { trip in
                        dateFormatter.string(from: trip.startTime)
                    }.mapValues { $0.count }
                    
                    tripData = tripCounts.map { dateString, count in
                        TripData(
                            date: dateFormatter.date(from: dateString) ?? Date(),
                            count: count
                        )
                    }.sorted { $0.date < $1.date }
                }
            }
    }
    
    // Add expense data fetching function
    private func fetchExpenseData() {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        print("Fetching expenses from \(startDate) to \(endDate)")
        
        // Create a dispatch group to handle multiple async calls
        let group = DispatchGroup()
        var allExpenses: [ExpenseData] = []
        
        // Fetch trip expenses
        group.enter()
        db.collection("trips")
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching trip expenses: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let tripCharges = document.data()["tripCharges"] as? [String: Any] {
                            // Process fuel expenses
                            if let fuelAmount = tripCharges["fuelLog"] as? Double {
                                allExpenses.append(ExpenseData(
                                    category: "Fuel",
                                    amount: fuelAmount,
                                    date: document.data()["startTime"] as? Date ?? Date()
                                ))
                            }
                            
                            // Process toll expenses
                            if let tollAmount = tripCharges["tollFees"] as? Double {
                                allExpenses.append(ExpenseData(
                                    category: "Toll",
                                    amount: tollAmount,
                                    date: document.data()["startTime"] as? Date ?? Date()
                                ))
                            }
                            
                            // Process misc expenses
                            if let miscAmount = tripCharges["misc"] as? Double {
                                allExpenses.append(ExpenseData(
                                    category: "Miscellaneous",
                                    amount: miscAmount,
                                    date: document.data()["startTime"] as? Date ?? Date()
                                ))
                            }
                        }
                    }
                }
            }
        
        // Fetch maintenance expenses
        group.enter()
        db.collection("maintenance_tasks")
            .whereField("completionDate", isGreaterThanOrEqualTo: startDate)
            .whereField("completionDate", isLessThanOrEqualTo: endDate)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching maintenance expenses: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let partsCost = document.data()["partsCost"] as? Double {
                            allExpenses.append(ExpenseData(
                                category: "Parts",
                                amount: partsCost,
                                date: document.data()["completionDate"] as? Date ?? Date()
                            ))
                        }
                        
                        if let laborCost = document.data()["laborCost"] as? Double {
                            allExpenses.append(ExpenseData(
                                category: "Labor",
                                amount: laborCost,
                                date: document.data()["completionDate"] as? Date ?? Date()
                            ))
                        }
                    }
                }
            }
        
        // When all fetches are complete, update the UI
        group.notify(queue: .main) {
            if allExpenses.isEmpty {
                print("No expenses found, using sample data")
                // Add sample data for testing with actual categories from our model
                self.expenseData = [
                    ExpenseData(category: "Fuel", amount: 2500.0, date: Date()),
                    ExpenseData(category: "Toll", amount: 800.0, date: Date()),
                    ExpenseData(category: "Miscellaneous", amount: 500.0, date: Date()),
                    ExpenseData(category: "Parts", amount: 1800.0, date: Date()),
                    ExpenseData(category: "Labor", amount: 1200.0, date: Date())
                ]
            } else {
                print("Found \(allExpenses.count) expenses")
                // Group expenses by category and sum the amounts
                let groupedExpenses = Dictionary(grouping: allExpenses) { $0.category }
                    .mapValues { expenses in
                        expenses.reduce(0) { $0 + $1.amount }
                    }
                
                self.expenseData = groupedExpenses.map { category, amount in
                    ExpenseData(
                        category: category,
                        amount: amount,
                        date: Date()
                    )
                }
                print("Updated expenseData with \(self.expenseData.count) categories")
            }
        }
    }
}


struct FleetProfileRow: View {
    var title: String
    @Binding var value: String
    var isEditable: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            if isEditable {
                TextField("", text: $value)
                    .foregroundColor(.blue) // Only characters turn blue
                    .multilineTextAlignment(.trailing)
            } else {
                Text(value)
                    .foregroundColor(.primary)
            }
        }
    }
}


struct FleetProfileRowInt: View {
    var title: String
    @Binding var value: Int
    var isEditable: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            if isEditable {
                TextField("", value: $value, formatter: NumberFormatter())
                    .foregroundColor(.blue) // Only characters turn blue
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            } else {
                Text("\(value)") // Placeholder, adjust based on date format
                    .foregroundColor(.primary)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCardGridView: View {
    var icon: String
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(30)
        .shadow(color: Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AlertRowView: View {
    let message: String
    let time: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(message)
                    .font(.subheadline)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

class TripsViewModel: ObservableObject {
    @Published var totalTrips: Int = 0
    private let db = Firestore.firestore()
    
    func fetchTotalTrips() {
        db.collection("trips").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching trips: \(error.localizedDescription)")
                return
            }
            self.totalTrips = querySnapshot?.documents.count ?? 0
        }
    }
}

#Preview{
    MainTabView(authVM: AuthViewModel())
}

//hello

struct FilterChip: View {
    let title: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

struct FleetFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStatus: MaintenanceTask.TaskStatus?
    @Binding var selectedPriority: String?
    @Binding var selectedVehicle: String?
    @Binding var dateRange: ClosedRange<Date>
    let vehicles: [String]
    
    let priorities = ["High", "Medium", "Low"]
    let statuses: [MaintenanceTask.TaskStatus] = [.pending, .inProgress, .completed, .cancelled]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    ForEach(statuses, id: \.self) { status in
                        FilterRow(
                            title: status.rawValue.capitalized,
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = selectedStatus == status ? nil : status
                        }
                    }
                }
                
                Section("Priority") {
                    ForEach(priorities, id: \.self) { priority in
                        FilterRow(
                            title: priority,
                            isSelected: selectedPriority == priority
                        ) {
                            selectedPriority = selectedPriority == priority ? nil : priority
                        }
                    }
                }
                
                Section("Vehicle") {
                    ForEach(vehicles, id: \.self) { vehicle in
                        FilterRow(
                            title: vehicle,
                            isSelected: selectedVehicle == vehicle
                        ) {
                            selectedVehicle = selectedVehicle == vehicle ? nil : vehicle
                        }
                    }
                }
                
                Section("Date Range") {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { dateRange.lowerBound },
                            set: { dateRange = $0...dateRange.upperBound }
                        ),
                        displayedComponents: [.date]
                    )
                    
                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { dateRange.upperBound },
                            set: { dateRange = dateRange.lowerBound...$0 }
                        ),
                        displayedComponents: [.date]
                    )
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
}
