import SwiftUI
import Charts
import MapKit
import PhotosUI
import Firebase
import PDFKit

// MainTabView (unchanged, no colors)
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

// MaintenanceView
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
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

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
                    HStack(spacing: 16) {
                        StatCardGridView(
                            icon: "wrench.fill",
                            title: "Pending Tasks",
                            value: "\(viewModel.pendingTasks)",
                            color: isColorBlindMode ? .cbOrange : .orange
                        )
                        StatCardGridView(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            value: "\(viewModel.completedTasks)",
                            color: isColorBlindMode ? .cbOrange : .green
                        )
                    }
                    .padding(.horizontal)

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
                                    .background(isColorBlindMode ? Color.cbBlue.opacity(0.1) : Color.gray.opacity(0.1))
                                    .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
                                    .cornerRadius(8)
                                }
                            }
                            if let status = selectedStatus {
                                FilterChip(
                                    title: status.rawValue.capitalized,
                                    color: isColorBlindMode ? .cbBlue : .blue
                                ) {
                                    selectedStatus = nil
                                }
                            }
                            if let priority = selectedPriority {
                                FilterChip(
                                    title: priority,
                                    color: isColorBlindMode ? .cbOrange : priorityColor(priority)
                                ) {
                                    selectedPriority = nil
                                }
                            }
                            if let vehicle = selectedVehicle {
                                FilterChip(
                                    title: vehicle,
                                    color: isColorBlindMode ? .cbBlue : .purple
                                ) {
                                    selectedVehicle = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

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
                            .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
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
        case "high": return isColorBlindMode ? .cbOrange : .red
        case "medium": return isColorBlindMode ? .cbOrange : .orange
        case "low": return isColorBlindMode ? .cbOrange : .green
        default: return isColorBlindMode ? .cbBlue : .gray
        }
    }
}

// TaskCardView
struct TaskCardView: View {
    let task: MaintenanceTask
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var vehicleNumber: String = ""
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicleNumber)
                        .font(.headline)
                    Text(task.issue)
                        .font(.subheadline)
                        .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
                }
                Spacer()
                ManagerStatusBadge(status: task.status)
            }
            HStack {
                ManagerPriorityBadge(priority: task.priority)
                Spacer()
                Text("Due: \(task.completionDate)")
                    .font(.caption)
                    .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.05) : Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
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

// ManagerStatusBadge
struct ManagerStatusBadge: View {
    let status: MaintenanceTask.TaskStatus
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

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
        case .pending: return isColorBlindMode ? .cbOrange : .orange
        case .inProgress: return isColorBlindMode ? .cbBlue : .blue
        case .completed: return isColorBlindMode ? .cbOrange : .green
        case .cancelled: return isColorBlindMode ? .cbOrange : .red
        }
    }
}

// ManagerPriorityBadge
struct ManagerPriorityBadge: View {
    let priority: String
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

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
        case "high": return isColorBlindMode ? .cbOrange : .red
        case "medium": return isColorBlindMode ? .cbOrange : .orange
        case "low": return isColorBlindMode ? .cbOrange : .green
        default: return isColorBlindMode ? .cbBlue : .gray
        }
    }
}

// TaskDetailView
struct TaskDetailView: View {
    let task: MaintenanceTask
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AssignTaskViewModel()
    @State private var showingStatusSheet = false
    @State private var selectedStatus: MaintenanceTask.TaskStatus?
    @State private var vehicleNumber: String = ""
    @State private var showingCompletionView = false
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                    .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.05) : Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)

                    Button(action: { showingStatusSheet = true }) {
                        Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isColorBlindMode ? Color.cbBlue.opacity(0.1) : Color.blue.opacity(0.1))
                            .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
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
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Update Status", isPresented: $showingStatusSheet) {
                Button("Mark as Pending") { updateStatus(.pending) }
                Button("Mark as In Progress") { updateStatus(.inProgress) }
                Button("Mark as Completed") { showingCompletionView = true }
                Button("Mark as Cancelled") { updateStatus(.cancelled) }
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

// InfoRow
struct InfoRow: View {
    let title: String
    let value: String
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// TrackView (unchanged, no colors)
struct TrackView: View {
    var body: some View {
        Text("Track View")
            .font(.title)
    }
}

// DriverStatsViewModel (unchanged, no colors)
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

// Chart Data Models (unchanged, no colors)
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

// VehicleStatusChart
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
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow
    }
}

// MaintenanceTaskChart
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
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow
        
    }
}


// TripTrendChart
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
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow
    }
}

// ExpenseChart
struct ExpenseChart: View {
    let data: [ExpenseData]
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false
    
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
                .cornerRadius(20)
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
                    "Fuel": isColorBlindMode ? .blue : .yellow,
                    "Toll": .orange,
                    "Miscellaneous": isColorBlindMode ? .blue : .purple,
                    "Parts": isColorBlindMode ? .orange : .blue,
                    "Labor": isColorBlindMode ? .blue : .green
                ])
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow
    }
}

// ExpenseData (for reference)
//struct ExpenseData: Identifiable {
//    let id = UUID()
//    let category: String
//    let amount: Double
//    let date: Date
//}

// ChartType Enum
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

    func color(isColorBlindMode: Bool) -> Color {
        if isColorBlindMode {
            return .cbBlue
        }
        switch self {
        case .vehicleStatus: return .blue
        case .maintenance: return .orange
        case .trips: return .green
        case .expenses: return .purple
        }
    }
}

// Add new AllDeviationsView
struct AllDeviationsView: View {
    @ObservedObject var dashboardVM: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(dashboardVM.recentDeviations) { deviation in
                        AlertRowView(
                            message: "\(deviation.driverName) deviated from route in \(deviation.vehicleNumber) (Trip: \(deviation.formattedTripId)) by \(Int(deviation.distance))m",
                            time: timeAgoString(from: deviation.timestamp),
                            deviation: deviation
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("All Deviations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

// Update the recent alerts section in DashboardHomeView
struct DashboardHomeView: View {
    @State private var showProfile = false
    @State private var selectedAction: ActionType?
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var viewModel = TripsViewModel()
    @StateObject private var driverCountViewModel = DriverStatsViewModel()
    @State private var vehicleStatusData: [VehicleStatusData] = []
    @State private var maintenanceTaskData: [MaintenanceTaskData] = []
    @State private var tripData: [TripData] = []
    @State private var expenseData: [ExpenseData] = []
    @State private var selectedChart: ChartType = .vehicleStatus
    @State private var showingAllDeviations = false
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    enum ActionType: Identifiable {
        case assign, maintain, track, reports
        var id: Int { hashValue }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 10) {
                        NavigationLink(destination: LogbookView()) {
                            StatCardGridView(
                                icon: "book.fill",
                                title: "Driver Logbook",
                                value: "\(driverCountViewModel.driverCount)",
                                color: isColorBlindMode ? .cbBlue : .blue
                            )
                        }
                        .onAppear { driverCountViewModel.fetchDriverCount() }
                        NavigationLink(destination: AllTripsView()) {
                            StatCardGridView(
                                icon: "location.fill",
                                title: "Total Trips",
                                value: "\(viewModel.totalTrips)",
                                color: isColorBlindMode ? .cbOrange : .teal
                            )
                        }
                        .onAppear { viewModel.fetchTotalTrips() }
                        NavigationLink(destination: MaintenanceView()) {
                            StatCardGridView(
                                icon: "wrench.fill",
                                title: "Maintenance",
                                value: "\(dashboardVM.pendingMaintenanceTasks)",
                                color: isColorBlindMode ? .cbOrange : .red
                            )
                        }
                        NavigationLink(destination: TicketListView()) {
                            StatCardGridView(
                                icon: "ticket.fill",
                                title: "Tickets",
                                value: "\(dashboardVM.activeTickets)",
                                color: isColorBlindMode ? .cbOrange : .orange
                            )
                        }
                    }
                    .padding(.horizontal)

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
                        case .reports: ReportsView()
                        case .assign: AssignView()
                        case .maintain: AssignTaskView()
                        case .track: TrackView()
                        }
                    }
                    .padding(.horizontal)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .shadow(color: .gray.opacity(0.1), radius: 10, x: 0, y: 0)
                    .cornerRadius(30)
                    .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.08) : Color(.label).opacity(0.08), radius: 4)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
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
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedChart == type ? type.color(isColorBlindMode: isColorBlindMode).opacity(0.2) : Color(.systemGray6))
                                        )
                                        .foregroundColor(selectedChart == type ? type.color(isColorBlindMode: isColorBlindMode) : (isColorBlindMode ? .cbBlue : .gray))
                                        .shadow(color: .gray.opacity(0.1), radius: 10, x: 0, y: 5) // Added shadow
                                        
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)

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

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Alerts")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingAllDeviations = true }) {
                                Text("See All")
                                    .font(.subheadline)
                                    .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                            }
                        }
                        VStack(spacing: 12) {
                            ForEach(Array(dashboardVM.recentDeviations.prefix(5))) { deviation in
                                AlertRowView(
                                    message: "\(deviation.driverName) deviated from route in \(deviation.vehicleNumber) (Trip: \(deviation.formattedTripId)) by \(Int(deviation.distance))m",
                                    time: timeAgoString(from: deviation.timestamp),
                                    deviation: deviation
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(30)
                    .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.08) : Color(.label).opacity(0.08), radius: 5)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hello,Manager !")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                showProfileView()
            }
            .sheet(isPresented: $showingAllDeviations) {
                AllDeviationsView(dashboardVM: dashboardVM)
            }
            .onAppear {
                dashboardVM.fetchVehicleStats()
                dashboardVM.fetchRecentDeviations()
                fetchChartData()
                fetchExpenseData()
            }
        }
    }
    
    // Update fetchExpenseData in DashboardHomeView
    private func fetchExpenseData() {
            let db = Firestore.firestore()
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
            let group = DispatchGroup()
            var allExpenses: [ExpenseData] = []

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
                                if let fuelAmount = tripCharges["fuelLog"] as? Double {
                                    allExpenses.append(ExpenseData(
                                        category: "Fuel",
                                        amount: fuelAmount,
                                        date: document.data()["startTime"] as? Date ?? Date()
                                    ))
                                }
                                if let tollAmount = tripCharges["tollFees"] as? Double {
                                    allExpenses.append(ExpenseData(
                                        category: "Toll",
                                        amount: tollAmount,
                                        date: document.data()["startTime"] as? Date ?? Date()
                                    ))
                                }
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

            group.notify(queue: .main) {
                if allExpenses.isEmpty {
                    print("No expenses found, using sample data")
                    self.expenseData = [
                        ExpenseData(category: "Fuel", amount: 2500.0, date: Date()),
                        ExpenseData(category: "Toll", amount: 800.0, date: Date()),
                        ExpenseData(category: "Miscellaneous", amount: 500.0, date: Date()),
                        ExpenseData(category: "Parts", amount: 1800.0, date: Date()),
                        ExpenseData(category: "Labor", amount: 1200.0, date: Date())
                    ]
                } else {
                    print("Found \(allExpenses.count) expenses")
                    let groupedExpenses = Dictionary(grouping: allExpenses) { $0.category }
                        .mapValues { expenses in
                            expenses.reduce(0) { $0 + $1.amount }
                        }
                    self.expenseData = groupedExpenses.map { category, amount in
                        ExpenseData(
                            category: category.trimmingCharacters(in: .whitespacesAndNewlines).capitalized,
                            amount: amount,
                            date: Date()
                        )
                    }
                    print("Updated expenseData with \(self.expenseData.count) categories: \(self.expenseData.map { $0.category })")
                }
            }
        }

    private func fetchChartData() {
        let db = Firestore.firestore()
        db.collection("vehicles").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let vehicles = documents.compactMap { try? $0.data(as: Vehicle.self) }
                let statusCounts = Dictionary(grouping: vehicles) { $0.status.rawValue }
                    .mapValues { $0.count }
                vehicleStatusData = statusCounts.map { VehicleStatusData(status: $0.key, count: $0.value) }
            }
        }
        db.collection("maintenance_tasks").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let tasks = documents.compactMap { try? $0.data(as: MaintenanceTask.self) }
                let statusCounts = Dictionary(grouping: tasks) { $0.status.rawValue }
                    .mapValues { $0.count }
                maintenanceTaskData = statusCounts.map { MaintenanceTaskData(category: $0.key, count: $0.value) }
            }
        }
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

    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

// FleetProfileRow
struct FleetProfileRow: View {
    var title: String
    @Binding var value: String
    var isEditable: Bool
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
            Spacer()
            if isEditable {
                TextField("", text: $value)
                    .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                    .multilineTextAlignment(.trailing)
            } else {
                Text(value)
                    .foregroundColor(.primary)
            }
        }
    }
}

// FleetProfileRowInt
struct FleetProfileRowInt: View {
    var title: String
    @Binding var value: Int
    var isEditable: Bool
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
            Spacer()
            if isEditable {
                TextField("", value: $value, formatter: NumberFormatter())
                    .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
            } else {
                Text("\(value)")
                    .foregroundColor(.primary)
            }
        }
    }
}

// QuickActionButton
struct QuickActionButton: View {
    let icon: String
    let title: String
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                .frame(width: 60, height: 60)
                .background(isColorBlindMode ? Color.cbBlue.opacity(0.1) : Color.blue.opacity(0.1))
                .clipShape(Circle())
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        
    }
}

// StatCardGridView
struct StatCardGridView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isColorBlindMode ? Color.cbBlue.opacity(0.2) : color.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(isColorBlindMode ? .cbBlue : color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(30)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow
    }
}

// AlertRowView
struct AlertRowView: View {
    let message: String
    let time: String
    let deviation: GeofenceDeviation
    @State private var showingDetail = false
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(isColorBlindMode ? .cbOrange : .red)
                    .padding(8)
                    .background(isColorBlindMode ? Color.cbOrange.opacity(0.1) : Color.red.opacity(0.1))
                    .clipShape(Circle())
                VStack(alignment: .leading) {
                    Text(message)
                        .font(.subheadline)
                    Text(time)
                        .font(.caption)
                        .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
                    .font(.caption)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.05) : Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            GeofenceDeviationDetailView(deviation: deviation)
        }

        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: isColorBlindMode ? Color.cbBlue.opacity(0.05) : Color(.label).opacity(0.05), radius: 4, x: 0, y: 2)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5) // Added shadow

    }
}

// TripsViewModel (unchanged, no colors)
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

// FilterChip
struct FilterChip: View {
    let title: String
    let color: Color
    let onRemove: () -> Void
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

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
        .background(isColorBlindMode ? Color.cbBlue.opacity(0.1) : color.opacity(0.1))
        .foregroundColor(isColorBlindMode ? .cbBlue : color)
        .cornerRadius(8)
    }
}

// FleetFilterView
struct FleetFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStatus: MaintenanceTask.TaskStatus?
    @Binding var selectedPriority: String?
    @Binding var selectedVehicle: String?
    @Binding var dateRange: ClosedRange<Date>
    let vehicles: [String]
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

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
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// FilterRow
struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(isColorBlindMode ? .cbBlue : .blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
}


// Rename DetailRow to DeviationDetailRow
struct DeviationDetailRow: View {
    let title: String
    let value: String
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(isColorBlindMode ? .cbBlue : .gray)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// Update GeofenceDeviationDetailView to use DeviationDetailRow
struct GeofenceDeviationDetailView: View {
    let deviation: GeofenceDeviation
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @AppStorage("isColorBlindMode") private var isColorBlindMode: Bool = false
    
    init(deviation: GeofenceDeviation) {
        self.deviation = deviation
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: deviation.latitude,
                longitude: deviation.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Map View
                    Map(coordinateRegion: $region, annotationItems: [deviation]) { item in
                        MapMarker(
                            coordinate: CLLocationCoordinate2D(
                                latitude: item.latitude,
                                longitude: item.longitude
                            ),
                            tint: isColorBlindMode ? .cbOrange : .red
                        )
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    // Details
                    VStack(spacing: 16) {
                        DeviationDetailRow(title: "Driver", value: deviation.driverName)
                        DeviationDetailRow(title: "Vehicle", value: deviation.vehicleNumber)
                        DeviationDetailRow(title: "Trip ID", value: deviation.formattedTripId)
                        DeviationDetailRow(title: "Deviation", value: "\(Int(deviation.distance)) meters")
                        DeviationDetailRow(title: "Time", value: formatDate(deviation.timestamp))
                        DeviationDetailRow(title: "Location", value: "\(String(format: "%.6f", deviation.latitude)), \(String(format: "%.6f", deviation.longitude))")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Deviation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


// Preview
#Preview {
    MainTabView(authVM: AuthViewModel())
}



