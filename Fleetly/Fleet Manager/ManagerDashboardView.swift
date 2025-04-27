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
                        StatCardGridView(icon: "car.fill", title: "Total Vehicles", value: "120", color: .blue)
                        StatCardGridView(icon: "location.fill", title: "Active Trips", value: "24", color: .green)
                        StatCardGridView(icon: "wrench.fill", title: "Maintenance", value: "12", color: .orange)
                        StatCardGridView(icon: "exclamationmark.triangle.fill", title: "Alerts", value: "5", color: .red)
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
                                AlertRowView(message: "Vehicle 23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle 45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
                                AlertRowView(message: "Vehicle 23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle 45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
                                AlertRowView(message: "Vehicle 23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle 45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
                                AlertRowView(message: "Vehicle 23 speed exceeded", time: "5 mins ago")
                                AlertRowView(message: "Vehicle 45 needs maintenance", time: "10 mins ago")
                                AlertRowView(message: "Trip delay reported on Route 8", time: "30 mins ago")
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
        }
    }
}


import SwiftUI
import PhotosUI

struct showProfileView: View {
    @State private var selectedItem: PhotosPickerItem?
     // Initial image
    @State private var imageData: Data? // To store image data for persistence
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: Image = Image("exampleImage")
    // Fleet Profile Details with Persistence
    @AppStorage("firstName") private var firstName = "Param"
    @AppStorage("lastName") private var lastName = "Patel"
    @AppStorage("dateOfBirth") private var dateOfBirth = Date()
    @AppStorage("fleetId") private var fleetId = "FM12345"
    @AppStorage("phoneNumber") private var phoneNumber = "+91-9876543210"
    @AppStorage("emailId") private var emailId = "param.patel@example.com"
    @AppStorage("driversLicense") private var driversLicense = ""
    @AppStorage("allowNotifications") private var allowNotifications = false
    @State private var isEditing = false
    @StateObject var authVM = AuthViewModel()
    
    
    // Date range for DatePicker
    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -100, to: Date())!
        let maxDate = Date()
        return minDate...maxDate
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                                imageData = data // Store image data for saving
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Fleet Manager Details")) {
                    FleetProfileRow(title: "First Name", value: $firstName, isEditable: isEditing)
                    FleetProfileRow(title: "Last Name", value: $lastName, isEditable: isEditing)
                    if isEditing {
                        DatePicker("Date of Birth", selection: $dateOfBirth, in: dateRange, displayedComponents: [.date])
                            .foregroundColor(.blue)
                    } else {
                        HStack {
                            Text("Date of Birth")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(dateOfBirth, style: .date)
                                .foregroundColor(.primary)
                        }
                    }
                    FleetProfileRow(title: "Fleet ID", value: $fleetId, isEditable: isEditing)
                    FleetProfileRow(title: "Phone Number", value: $phoneNumber, isEditable: isEditing)
                    FleetProfileRow(title: "Email ID", value: $emailId, isEditable: isEditing)
                }
                
                Section {
                    NavigationLink(destination: TermsAndAgreementView()) {
                        HStack {
                            Text("Terms and Conditions")
                            Spacer()}}}
                
                
                Section {

                    Toggle(isOn: $allowNotifications) {
                        Text("Allow Notifications")
                        Text("Enable to receive updates about fleet assignments and maintenance schedules.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Section {
                    Button(action: {
                        authVM.logout()
                        
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Fleet Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Save") {
                        if isEditing {
                            loadDefaultValues()
                        }
                        isEditing = false
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            saveChanges()
                        }
                        isEditing.toggle()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                loadSavedImage()
            }
        }
    }
    
    // Load saved image data
    private func loadSavedImage() {
            if let savedData = UserDefaults.standard.data(forKey: "profileImage"),
               let uiImage = UIImage(data: savedData) {
                profileImage = Image(uiImage: uiImage)
                print("Image loaded from UserDefaults: \(savedData.count) bytes")
            } else {
                print("No saved image found or failed to load")
            }
        }
    
    // Load default values for reverting on Cancel
    private func loadDefaultValues() {
        firstName = UserDefaults.standard.string(forKey: "firstName") ?? "Param"
        lastName = UserDefaults.standard.string(forKey: "lastName") ?? "Patel"
        dateOfBirth = UserDefaults.standard.object(forKey: "dateOfBirth") as? Date ?? Date()
        fleetId = UserDefaults.standard.string(forKey: "fleetId") ?? "FM12345"
        phoneNumber = UserDefaults.standard.string(forKey: "phoneNumber") ?? "+91-9876543210"
        emailId = UserDefaults.standard.string(forKey: "emailId") ?? "param.patel@example.com"
        
        allowNotifications = UserDefaults.standard.bool(forKey: "allowNotifications")
    }
    
    // Save all changes including image
    private func saveChanges() {
        UserDefaults.standard.set(firstName, forKey: "firstName")
        UserDefaults.standard.set(lastName, forKey: "lastName")
        UserDefaults.standard.set(dateOfBirth, forKey: "dateOfBirth")
        UserDefaults.standard.set(fleetId, forKey: "fleetId")
        UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        UserDefaults.standard.set(emailId, forKey: "emailId")
        UserDefaults.standard.set(allowNotifications, forKey: "allowNotifications")
        if let imageData = imageData {
            UserDefaults.standard.set(imageData, forKey: "profileImage")
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

#Preview {
    showProfileView()
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




struct TermsAndAgreementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms and Agreement")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("""
                    Please read these terms and conditions carefully before using our fleet management application.

                    1. **Acceptance of Terms**
                    By accessing or using this application, you agree to be bound by these Terms and Conditions.

                    2. **Use of Application**
                    This application is provided for managing fleet operations, including driver and vehicle information. You agree to use it only for lawful purposes.

                    3. **User Responsibilities**
                    You are responsible for maintaining the confidentiality of your account information and for all activities under your account.

                    4. **Data Privacy**
                    We collect and process personal data in accordance with our Privacy Policy. By using this application, you consent to such processing.

                    5. **Termination**
                    We reserve the right to terminate or suspend access to the application at any time without prior notice.

                    For the full terms, please contact our support team or visit our website.
                    """)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding()
        }
        .navigationTitle("")
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
