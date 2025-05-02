import SwiftUI
import Charts
import MapKit
import PhotosUI
import Firebase

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
    var body: some View {
        AssignTaskView()
    }
}

struct ReportsView: View {
    var body: some View {
        Text("Reports View")
            .font(.title)
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

struct DashboardHomeView: View {
    @State private var showProfile = false
    @State private var selectedAction: ActionType?
    @StateObject private var dashboardVM = DashboardViewModel() // Add DashboardViewModel
    @StateObject private var viewModel = TripsViewModel()
    @StateObject private var driverCountViewModel = DriverStatsViewModel()

    enum ActionType: Identifiable {
        case assign, maintain, reports, track

        var id: Int {
            hashValue
        }
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
                                title: "Total Trips",
                                value: "\(viewModel.totalTrips)",
                                color: .teal
                            )
                        }
                        .onAppear{
                            viewModel.fetchTotalTrips()
                        }
                        StatCardGridView(
                            icon: "wrench.fill",
                            title: "Maintenance",
                            value: "\(dashboardVM.maintenanceVehicles)", // Dynamic value
                            color: .red
                        )
                        NavigationLink(destination:TicketListView()){
                            StatCardGridView(
                                icon: "ticket.fill",
                                title: "Active Tickets",
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
                        case .assign:
                            AssignView()
                        case .maintain:
                            MaintenanceView()
                        case .reports:
                            ReportsView()
                        case .track:
                            TrackView()
                        }
                    }
                    .padding(.horizontal)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(radius: 4)
                    .padding(.horizontal)

                    // MARK: - Analytics and Alerts
                    VStack(alignment: .leading, spacing: 16) {
                        // Chart Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Overview")
                                .font(.headline)
                            ChartView()
                                .frame(height: 200)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                        .padding(.horizontal)

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
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(radius: 5)
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
                dashboardVM.fetchVehicleStats() // Start fetching vehicle stats
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
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ChartView: View {
    var body: some View {
        Chart {
            ForEach(MockData.weekData) { entry in
                BarMark(
                    x: .value("Day", entry.day),
                    y: .value("Trips", entry.value)
                )
                .foregroundStyle(by: .value("Day", entry.day))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: MockData.weekData.map { $0.day })
        }
    }
}





struct DataEntry: Identifiable {
    var id = UUID()
    let day: String
    let value: Int
}

struct MockData {
    static let weekData: [DataEntry] = [
        .init(day: "Mon", value: 0),
        .init(day: "Tue", value: 0),
        .init(day: "Wed", value: 0),
        .init(day: "Thu", value: 0),
        .init(day: "Fri", value: 0),
        .init(day: "Sat", value: 0),
        .init(day: "Sun", value: 0)
    ]
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
