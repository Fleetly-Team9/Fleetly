import SwiftUI
import MapKit
import CoreLocation
struct MainView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showProfile = false
    
    var body: some View {
        TabView {
            DriverHomePage(authVM: authVM, showProfile: $showProfile)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            PastRideContentView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
            TicketsView()
                .tabItem {
                    Label("Tickets", systemImage: "ticket.fill")
                }
        }
        .sheet(isPresented: $showProfile) {
            DriverProfileView(authVM: authVM)
        }
        .environmentObject(authVM) // Inject AuthViewModel into the environment for all tabs
    }
}

struct DriverHomePage: View {
    @ObservedObject var authVM: AuthViewModel
    @Binding var showProfile: Bool
    @State private var currentTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var isStopwatchRunning = false
    @State private var startTime: Date? = nil
    @State private var navigatingTripId: String? = nil
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var isClockedIn = false
    @State private var currentWorkOrderIndex: Int = 0
    @State private var swipeOffsets: [String: CGFloat] = [:]
    @State private var isDragCompleted: [String: Bool] = [:]
    @State private var isSwiping: [String: Bool] = [:]
    @StateObject private var assignedTripsVM = AssignedTripsViewModel()
    @State private var didStartListener = false
    @State private var profileImage: Image?

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let hours = (0...12).map { $0 == 0 ? "0hr" : "\($0)hr\($0 == 1 ? "" : "s")" }
    
    let dropoffLocation = "Kolkata"
    let vehicleNumber: String = "KA6A1204"
    private let profileImageKey = "profileImage"

    static let darkGray = Color(red: 68/255, green: 6/255, blue: 52/255)
    static let lightGray = Color(red: 240/255, green: 242/255, blue: 245/255)
    static let highlightYellow = Color(red: 235/255, green: 64/255, blue: 52/255)
    static let todayGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let customBlue = Color(.systemBlue)
    static let gradientStart = Color(red: 74/255, green: 145/255, blue: 226/255)
    static let gradientEnd = Color(red: 80/255, green: 227/255, blue: 195/255)
    static let initialCapsuleColor = Color(.systemGray5)
    
    private var maxX: CGFloat {
        return 363.0 - 53.0 // Capsule width - Circle diameter
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    private func initializeData() {
        guard let driverId = authVM.user?.id else { return }
        
        FirebaseManager.shared.fetchTodayWorkedTime(driverId: driverId) { result in
            switch result {
            case .success(let totalSeconds):
                elapsedTime = TimeInterval(totalSeconds)
                
                FirebaseManager.shared.fetchAttendanceRecord(driverId: driverId, date: currentDateString()) { recordResult in
                    switch recordResult {
                    case .success(let record):
                        if let record = record {
                            startTime = record.clockInTime.dateValue()
                            if let lastEvent = record.clockEvents.last {
                                isClockedIn = lastEvent.type == "clockIn"
                                isStopwatchRunning = isClockedIn
                            }
                        }
                    case .failure(let error):
                        print("Error fetching attendance record: \(error)")
                    }
                }
            case .failure(let error):
                print("Error fetching worked time: \(error)")
            }
        }
        
        // Load profile image from UserDefaults
        if let data = UserDefaults.standard.data(forKey: profileImageKey),
           let uiImage = UIImage(data: data) {
            profileImage = Image(uiImage: uiImage)
        } else {
            profileImage = nil
        }
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm a"
        return formatter
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d Hrs", hours, minutes, seconds)
    }
    
    private func isNewDay(_ start: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: start)
        let startOfNow = calendar.startOfDay(for: now)
        return startOfNow > startOfToday
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Here's your schedule for today!")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
            Button(action: {
                print("Profile image tapped") // Debug
                showProfile = true
            }) {
                Group {
                    if let profileImage = profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(Color.primary)
                    }
                }
                .contentShape(Circle()) // Ensure entire circle is tappable
            }
        }
        .padding(.horizontal)
    }
    
    private var workingHoursSection: some View {
        VStack {
            Text("Working Hours")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundStyle(Color.primary)
                .frame(width: 200, height: 50, alignment: .leading)
                .padding(.trailing, 150)
                .padding(.horizontal)
        }
    }
    
    private var workingHoursContent: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                .frame(width: 363, height: 290)
                .cornerRadius(10)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            
            VStack(spacing: 10) {
                Text(currentTime, formatter: dateFormatter)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .foregroundStyle(Color.primary)
                    .padding(.trailing, 210)
                    .padding(.top, 40)
                
                if !isClockedIn {
                    Text("Clocked Hours")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(Color.secondary)
                        .padding(.trailing, 200)
                } else {
                    Text("")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .frame(height: 20)
                        .padding(.trailing, 200)
                }
                
                Text(formatElapsedTime(elapsedTime))
                    .font(.system(size: 36, weight: .semibold, design: .default))
                    .foregroundStyle(Color.primary)
                    .padding(.leading, 0)
                    .padding(.trailing, 90)
                
                if !isClockedIn, let start = startTime {
                    Text("Since first in at \(start, formatter: timeFormatter)")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(Color.secondary)
                        .padding(.trailing, 130)
                } else {
                    Text("")
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundStyle(Color.secondary)
                        .padding(.trailing, 200)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 684, height: 12)
                                .padding(.horizontal, 10)
                            
                            let progressWidth: CGFloat = {
                                let maxTime: TimeInterval = 12 * 3600
                                let progress = min(elapsedTime / maxTime, 1.0)
                                return 684 * progress
                            }()
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(progressWidth, 0), height: 12)
                                .padding(.leading, 10)
                                .shadow(color: Color.blue.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            HStack(spacing: 0) {
                                ForEach(0..<13, id: \.self) { index in
                                    Rectangle()
                                        .fill(index % 3 == 0 ? Color.blue.opacity(0.6) : Color.blue.opacity(0.4))
                                        .frame(width: index % 3 == 0 ? 2 : 1.5, height: index % 3 == 0 ? 12 : 8)
                                        .padding(.leading, index == 0 ? 10 : 0)
                                    
                                    if index < 12 {
                                        Spacer()
                                            .frame(width: 684/12 - 2)
                                    }
                                }
                            }
                            
                            HStack(spacing: 0) {
                                ForEach(0..<49, id: \.self) { index in
                                    if index % 4 != 0 {
                                        Rectangle()
                                            .fill(Color.blue.opacity(0.25))
                                            .frame(width: 1, height: 5)
                                            .padding(.leading, index == 0 ? 10 : 0)
                                    } else {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: 1, height: 5)
                                    }
                                    
                                    if index < 48 {
                                        Spacer()
                                            .frame(width: 684/48 - 1)
                                    }
                                }
                            }
                            
                            if progressWidth > 0 {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    )
                                    .padding(.leading, progressWidth + 6)
                            }
                        }
                        
                        HStack(spacing: 0) {
                            ForEach(0..<13, id: \.self) { hour in
                                Text(hour == 0 ? "0hr" : "\(hour)hr\(hour == 1 ? "" : "s")")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .frame(width: 684/12)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .frame(width: 363)
                
                VStack {
                    Button(action: {
                        guard let driverId = authVM.user?.id else { return }
                        
                        isClockedIn.toggle()
                        let eventType = isClockedIn ? "clockIn" : "clockOut"
                        
                        FirebaseManager.shared.recordClockEvent(driverId: driverId, type: eventType) { result in
                            switch result {
                            case .success:
                                if isClockedIn {
                                    print("Driver Clocked in")
                                    isStopwatchRunning = true
                                } else {
                                    print("Driver Clocked out")
                                    isStopwatchRunning = false
                                    FirebaseManager.shared.fetchTodayWorkedTime(driverId: driverId) { timeResult in
                                        switch timeResult {
                                        case .success(let totalSeconds):
                                            elapsedTime = TimeInterval(totalSeconds)
                                        case .failure(let error):
                                            print("Error fetching updated worked time: \(error)")
                                        }
                                    }
                                }
                            case .failure(let error):
                                print("Error recording clock event: \(error)")
                                isClockedIn.toggle()
                            }
                        }
                    }) {
                        Label(isClockedIn ? "Clock Out" : "Clock In", systemImage: "person.crop.circle.badge.clock")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundStyle(Color.white)
                            .frame(width: 312, height: 35)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isClockedIn ? Color(red: 243/255, green: 120/255, blue: 89/255) : Color(red: 3/255, green: 218/255, blue: 164/255))
                    .padding(.bottom, 20)
                }
                Spacer()
            }
        }
        .offset(y: -25)
    }
    
    private var tripsHeader: some View {
        HStack {
            Text("Assigned Trips")
                .font(.title2.bold())
                .foregroundStyle(Color.primary)
            
            if !assignedTripsVM.assignedTrips.isEmpty {
                Text("\(assignedTripsVM.assignedTrips.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    struct TripMapData {
        var region: MKCoordinateRegion
        var pickup: Location?
        var drop: Location?
        var route: MKRoute?
        
        init() {
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            self.pickup = nil
            self.drop = nil
            self.route = nil
        }
    }
    
    @State private var tripMapData: [String: TripMapData] = [:]
    
    private func fetchRoute(for trip: Trip) {
        if tripMapData[trip.id] == nil {
            tripMapData[trip.id] = TripMapData()
        }
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(trip.startLocation) { placemarks, error in
            guard let startPlacemark = placemarks?.first,
                  let startLocation = startPlacemark.location else {
                print("Failed to geocode start location: \(trip.startLocation), error: \(String(describing: error))")
                return
            }
            
            geocoder.geocodeAddressString(trip.endLocation) { placemarks, error in
                guard let endPlacemark = placemarks?.first,
                      let endLocation = endPlacemark.location else {
                    print("Failed to geocode end location: \(trip.endLocation), error: \(String(describing: error))")
                    return
                }
                
                let pickup = Location(name: trip.startLocation, coordinate: startLocation.coordinate)
                let drop = Location(name: trip.endLocation, coordinate: endLocation.coordinate)
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
                request.transportType = .automobile
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    guard let route = response?.routes.first else {
                        print("Failed to calculate route: \(String(describing: error))")
                        return
                    }
                    
                    let coordinates = route.polyline.coordinates
                    let region = MKCoordinateRegion(coordinates: coordinates, latitudinalMetersPadding: 1000, longitudinalMetersPadding: 1000)
                    
                    DispatchQueue.main.async {
                        tripMapData[trip.id]?.region = region
                        tripMapData[trip.id]?.pickup = pickup
                        tripMapData[trip.id]?.drop = drop
                        tripMapData[trip.id]?.route = route
                    }
                }
            }
        }
    }
    
    private struct TripMapSection: View {
        let mapData: TripMapData
        
        var body: some View {
            MapViewWithRoute(
                region: .constant(mapData.region),
                pickup: mapData.pickup ?? Location(name: "Default Start", coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)),
                drop: mapData.drop ?? Location(name: "Default End", coordinate: CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)),
                route: mapData.route,
                mapStyle: .constant(.standard),
                isTripStarted: false,
                userLocationCoordinate: nil,
                poiAnnotations: []
            )
            .frame(width: 363, height: 150)
            .cornerRadius(12)
        }
    }

    private struct TripLocationSection: View {
        let trip: Trip
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) { // Reduced spacing from 8 to 6
                LocationRow(icon: "location.fill", color: .green, label: "From", value: trip.startLocation)
                LocationRow(icon: "location.fill", color: .red, label: "To", value: trip.endLocation)
            }
        }
    }

    private struct LocationRow: View {
        let icon: String
        let color: Color
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                    Text(value)
                        .font(.headline)
                        .lineLimit(1)
                }
            }
        }
    }

    private struct TripDetailsSection: View {
        let trip: Trip
        
        var body: some View {
            HStack(spacing: 24) {
                DetailColumn(label: "Time", value: trip.time)
                DetailColumn(label: "Vehicle Type", value: trip.vehicleType)
                DetailColumn(
                    label: trip.vehicleType == "Passenger Vehicle" ? "Passengers" : "Load",
                    value: trip.vehicleType == "Passenger Vehicle" ?
                        "\(trip.passengers ?? 0)" :
                        "\(Int(trip.loadWeight ?? 0)) kg"
                )
            }
        }
    }

    private struct DetailColumn: View {
        let label: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) { // Reduced spacing from 4 to 2
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.headline)
            }
        }
    }

    struct TripActionButton: View {
        let trip: Trip
        @Binding var navigatingTripId: String?
        @Binding var swipeOffsets: [String: CGFloat]
        @Binding var isDragCompleted: [String: Bool]
        @Binding var isSwiping: [String: Bool]
        let maxX: CGFloat
        let authVM: AuthViewModel
        let gradientStart: Color
        let gradientEnd: Color
        @Environment(\.colorScheme) var colorScheme
        @State private var sliderOpacity: Double = 1.0
        
        private var swipeOffset: CGFloat {
            swipeOffsets[trip.id] ?? 0
        }
        
        private var isTripDragCompleted: Bool {
            isDragCompleted[trip.id] ?? false
        }
        
        private var isTripSwiping: Bool {
            isSwiping[trip.id] ?? false
        }
        
        private var isTripDateValid: Bool {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentDate = dateFormatter.string(from: Date())
            return trip.date == currentDate
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    NavigationLink(
                        destination: PreInspectionView(
                            authVM: authVM,
                            dropoffLocation: trip.endLocation,
                            vehicleNumber: trip.vehicleId,
                            tripID: trip.id,
                            vehicleID: trip.vehicleId
                        ),
                        isActive: Binding(
                            get: { navigatingTripId == trip.id },
                            set: { if !$0 { navigatingTripId = nil } }
                        ),
                        label: {
                            LinearGradient(
                                colors: swipeOffset == 0 ? [Color(.systemGray5), Color(.systemGray5)] : [
                                    gradientStart,
                                    swipeOffset >= maxX - 10 || isTripDragCompleted ? gradientEnd : gradientStart
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geometry.size.width, height: 55)
                            .clipShape(Capsule())
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isTripDateValid)
                    
                    HStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemBlue))
                                .frame(width: 53, height: 53)
                            Image(systemName: "car.side.fill")
                                .scaleEffect(x: -1, y: 1)
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .opacity(sliderOpacity)
                        .offset(x: swipeOffset)
                        .gesture(
                            isTripDragCompleted || !isTripDateValid ? nil : DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    isSwiping[trip.id] = true
                                    let calculatedMaxX = geometry.size.width - 53
                                    swipeOffsets[trip.id] = min(max(0, value.translation.width), calculatedMaxX)
                                }
                                .onEnded { _ in
                                    isSwiping[trip.id] = false
                                    let calculatedMaxX = geometry.size.width - 53
                                    if swipeOffset >= calculatedMaxX - 10 {
                                        swipeOffsets[trip.id] = calculatedMaxX
                                        isDragCompleted[trip.id] = true
                                        
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            sliderOpacity = 0
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            navigatingTripId = trip.id
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            swipeOffsets[trip.id] = 0
                                        }
                                    }
                                }
                        )
                        
                        Spacer()
                        
                        Text(isTripDateValid ? "Slide to get Ready" : "Trip not available today")
                            .font(.headline)
                            .foregroundColor(swipeOffset > 0 || isTripDragCompleted ? .white : Color(.systemBlue))
                            .padding(.trailing, 16)
                    }
                    .padding(.leading, 0)
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 55)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 8)
            .onAppear {
                resetSliderState()
            }
            .onChange(of: navigatingTripId) { newValue in
                if newValue != trip.id {
                    resetSliderState()
                }
            }
        }
        
        private func resetSliderState() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                swipeOffsets[trip.id] = 0
                isDragCompleted[trip.id] = false
                sliderOpacity = 1.0
            }
        }
    }
    
    private func tripCardView(for trip: Trip) -> some View {
        let mapData = tripMapData[trip.id] ?? TripMapData()
        
        return VStack(spacing: 0) {
            // Card wrapper that includes the map
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 0) {
                    // Map is now inside the card
                    MapViewWithRoute(
                        region: .constant(mapData.region),
                        pickup: mapData.pickup ?? Location(name: "Default Start", coordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946)),
                        drop: mapData.drop ?? Location(name: "Default End", coordinate: CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639)),
                        route: mapData.route,
                        mapStyle: .constant(.standard),
                        isTripStarted: false,
                        userLocationCoordinate: nil,
                        poiAnnotations: []
                    )
                    .frame(width: 363, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Trip Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            // Date and Time Row
                            HStack(spacing: 24) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(Color.blue)
                                        .frame(width: 20)
                                    Text(trip.date)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundStyle(Color.blue)
                                        .frame(width: 20)
                                    Text(trip.time)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Vehicle Type and Capacity Row
                            HStack(spacing: 24) {
                                HStack(spacing: 8) {
                                    Image(systemName: "car.fill")
                                        .foregroundStyle(Color.blue)
                                        .frame(width: 20)
                                    Text(trip.vehicleType)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if trip.vehicleType == "Passenger Vehicle" {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.2.fill")
                                            .foregroundStyle(Color.blue)
                                            .frame(width: 20)
                                        Text("\(trip.passengers ?? 0) Passengers")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else if let loadWeight = trip.loadWeight {
                                    HStack(spacing: 8) {
                                        Image(systemName: "shippingbox.fill")
                                            .foregroundStyle(Color.blue)
                                            .frame(width: 20)
                                        Text("\(Int(loadWeight)) kg")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Location Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            LocationRow(icon: "location.fill", color: .green, label: "From", value: trip.startLocation)
                            LocationRow(icon: "location.fill", color: .red, label: "To", value: trip.endLocation)
                        }
                        .padding(.horizontal, 20)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Action Button
                        TripActionButton(
                            trip: trip,
                            navigatingTripId: $navigatingTripId,
                            swipeOffsets: $swipeOffsets,
                            isDragCompleted: $isDragCompleted,
                            isSwiping: $isSwiping,
                            maxX: maxX,
                            authVM: authVM,
                            gradientStart: Self.gradientStart,
                            gradientEnd: Self.gradientEnd
                        )
                        .disabled(navigatingTripId != nil)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .frame(width: 363)
        .onAppear {
            fetchRoute(for: trip)
        }
    }
    
    private var tripsListView: some View {
        Group {
            if assignedTripsVM.assignedTrips.count == 1 {
                // Single trip: Display without ScrollView, aligned like Clock Card
                tripCardView(for: assignedTripsVM.assignedTrips[0])
            } else {
                // Multiple trips: Use ScrollView for horizontal scrolling
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(assignedTripsVM.assignedTrips.sorted(by: { $0.startTime < $1.startTime })) { trip in
                            tripCardView(for: trip)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyOrLoadingStateView: some View {
        Group {
            if assignedTripsVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else if !assignedTripsVM.assignedTrips.isEmpty {
                tripsListView
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "car.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.secondary)
                    Text("No trips assigned")
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
        }
    }
    
    private var assignedTripSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            tripsHeader
            emptyOrLoadingStateView
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemGray6))
                    .ignoresSafeArea(.all, edges: .top)
                    .ignoresSafeArea(.keyboard)
                
                ScrollView {
                    VStack {
                        headerSection
                        workingHoursSection
                        workingHoursContent
                        assignedTripSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .scrollIndicators(.hidden)
                .navigationTitle("Hello, \(authVM.user?.name ?? "Param Patel")")
                .onReceive(timer) { _ in
                    currentTime = Date()
                    if isStopwatchRunning {
                        elapsedTime += 1
                    }
                }
                .onAppear {
                    initializeData()
                    guard !didStartListener,
                          let driverId = authVM.user?.id
                    else { return }
                    assignedTripsVM.startListening(driverId: driverId)
                    didStartListener = true
                }
                .onChange(of: showProfile) { newValue in
                    if !newValue {
                        if let data = UserDefaults.standard.data(forKey: profileImageKey),
                           let uiImage = UIImage(data: data) {
                            profileImage = Image(uiImage: uiImage)
                        } else {
                            profileImage = nil
                        }
                    }
                }
            }
        }
    }
}

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], latitudinalMetersPadding: CLLocationDistance, longitudinalMetersPadding: CLLocationDistance) {
        guard !coordinates.isEmpty else {
            self.init(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            return
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + (latitudinalMetersPadding / 111320.0),
            longitudeDelta: (maxLon - minLon) + (longitudinalMetersPadding / (111320.0 * cos(center.latitude * .pi / 180.0)))
        )
        
        self.init(center: center, span: span)
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        coords.withUnsafeMutableBufferPointer { ptr in
            getCoordinates(ptr.baseAddress!, range: NSRange(location: 0, length: pointCount))
        }
        return coords
    }
}
