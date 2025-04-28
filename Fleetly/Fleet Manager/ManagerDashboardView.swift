import SwiftUI
import Charts
import MapKit
import PhotosUI

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




// AssignTripView.swift
struct AssignView: View {
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @ObservedObject var viewModel = LocationSearchViewModel()
    @State private var journeyDate = Date()
    @State private var passengers = 1
    @State private var selectedVehicle: Vehicle1?
    @State private var showVehicleSheet = false
    @State private var showDriverSheet = false
    @State private var selectedDriver: Driver1?
    @State private var journeyTime = Date()
    
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
                        TextField("From Location", text: $fromLocation)
                            .padding(.vertical, 10)
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
                                    fromLocation = result.title
                                    viewModel.fromSearchResults = [] // Clear from suggestions
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.blue)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        Text(result.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.fromSearchResults)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // To Location
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        TextField("To Location", text: $toLocation)
                            .padding(.vertical, 10)
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
                                    toLocation = result.title
                                    viewModel.toSearchResults = [] // Clear to suggestions
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.green)
                                            .frame(width: 24, height: 24)
                                            .padding(.trailing, 4)
                                        
                                        Text(result.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
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
                        .animation(.easeInOut(duration: 0.25), value: viewModel.toSearchResults)
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
                
                Section(header: Text("Passengers").font(.subheadline)) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Stepper(value: $passengers, in: 1...10) {
                            Text("Passengers: \(passengers)")
                        }
                    }
                }
                
                Section(header: Text("Assignments").font(.headline)) {
                    HStack {
                        Image(systemName: "car.fill")
                        Button(action: { showVehicleSheet = true }) {
                            Text(selectedVehicle?.model ?? "Not Assigned")
                                .foregroundStyle(.primary)
                        }
                    }
                    HStack {
                        Image(systemName: "person.fill")
                        Button(action: { showDriverSheet = true }) {
                            Text("\(selectedDriver?.firstName ?? "Not Assigned") \(selectedDriver?.lastName ?? "")")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { /* Action */ }) {
                        Text("Assign")
                            .foregroundColor(.blue)
                            .font(.system(size: 17))
                    }
                }
            }
            .sheet(isPresented: $showVehicleSheet) {
                MockVehicleListView(selectedVehicle: $selectedVehicle)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
            .sheet(isPresented: $showDriverSheet) {
                MockDriverListView(selectedDriver: $selectedDriver)
                    .presentationDetents([.medium, .large])
                    .cornerRadius(30)
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}




struct MaintenanceView: View {
    var body: some View {
        Text("Maintenance View")
            .font(.title)
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


// Dashboard Home View
struct DashboardHomeView: View {
    @State private var showProfile = false
    @State private var selectedAction: ActionType?
    @StateObject private var dashboardVM = DashboardViewModel() // Add DashboardViewModel

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

                    LazyVGrid(columns: columns, spacing: 16) {
                        StatCardGridView(
                            icon: "car.fill",
                            title: "Total Vehicles",
                            value: "\(dashboardVM.totalVehicles)", // Dynamic value
                            color: .blue
                        )
                        StatCardGridView(
                            icon: "location.fill",
                            title: "Active Trips",
                            value: "0", // Still hardcoded, can be made dynamic later
                            color: .green
                        )
                        StatCardGridView(
                            icon: "wrench.fill",
                            title: "Maintenance",
                            value: "\(dashboardVM.maintenanceVehicles)", // Dynamic value
                            color: .orange
                        )
                        StatCardGridView(
                            icon: "exclamationmark.triangle.fill",
                            title: "Alerts",
                            value: "0", // Still hardcoded, can be made dynamic later
                            color: .red
                        )
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
