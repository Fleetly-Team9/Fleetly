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
                    Label("Tickets", systemImage: "ticket")
                }
        }
        .sheet(isPresented: $showProfile) {
            DriverProfileView(authVM: authVM)
        }
    }
}

struct DriverHomePage: View {
    @ObservedObject var authVM: AuthViewModel
    @Binding var showProfile: Bool
    @State private var currentTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var isStopwatchRunning = false
    @State private var startTime: Date? = nil
    @State private var isNavigating = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var isClockedIn = false
    @State private var currentWorkOrderIndex: Int = 0
    @StateObject private var assignedTripsVM = AssignedTripsViewModel()
    @State private var didStartListener = false
    @State private var profileImage: Image?
    @State private var showClockInAlert = false
    @State private var tripStates: [String: TripCardState] = [:] // Per-trip state for slider

    struct TripCardState {
        var swipeOffset: CGFloat = 0
        var isSwiping: Bool = false
        var isDragCompleted: Bool = false
        var isNavigating: Bool = false
    }

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
    
    private var maxX: CGFloat {
        let capsuleWidth = 280.0
        let circleWidth = 48.0
        return capsuleWidth - circleWidth
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
        return String(format: "%02d:%02d:%02d HRS", hours, minutes, seconds)
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
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: {
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
                            .foregroundStyle(.primary)
                    }
                }
                .contentShape(Circle())
            }
        }
        .padding(.horizontal)
    }
    
    private var workingHoursSection: some View {
        VStack {
            Text("Working Hours")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    private var workingHoursContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(width: 363, height: 290)
                .shadow(color: .black.opacity(0.1), radius: 5)
            
            VStack(spacing: 10) {
                Text(currentTime, formatter: dateFormatter)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.leading, 20)
                
                if !isClockedIn {
                    Text("Clocked Hours")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                }
                
                Text(formatElapsedTime(elapsedTime))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                if !isClockedIn, let start = startTime {
                    Text("Since first in at \(start, formatter: timeFormatter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 5) {
                        ZStack {
                            Rectangle()
                                .fill(.blue.opacity(0.1))
                                .frame(width: 684, height: 12)
                                .padding(.horizontal, 10)
                            
                            let progressWidth: CGFloat = {
                                let maxTime: TimeInterval = 12 * 3600
                                let progress = min(elapsedTime / maxTime, 1.0)
                                return 684 * progress
                            }()
                            
                            Rectangle()
                                .fill(.blue)
                                .frame(width: progressWidth, height: 12)
                                .padding(.horizontal, 10)
                            
                            HStack(spacing: 0) {
                                ForEach(0..<12, id: \.self) { index in
                                    Spacer()
                                        .frame(width: 40 + 12)
                                    Rectangle()
                                        .fill(.blue.opacity(0.5))
                                        .frame(width: 1, height: 8)
                                        .offset(x: -26)
                                }
                                Spacer()
                                    .frame(width: 40)
                            }
                            .padding(.horizontal, 10)
                        }
                        
                        HStack(spacing: 15) {
                            ForEach(hours, id: \.self) { hour in
                                Text(hour)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .frame(width: 40)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    guard let driverId = authVM.user?.id else { return }
                    
                    isClockedIn.toggle()
                    let eventType = isClockedIn ? "clockIn" : "clockOut"
                    
                    FirebaseManager.shared.recordClockEvent(driverId: driverId, type: eventType) { result in
                        switch result {
                        case .success:
                            if isClockedIn {
                                isStopwatchRunning = true
                            } else {
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
                    Text(isClockedIn ? "Clock Out" : "Clock In")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isClockedIn ? .red : .green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var tripsHeader: some View {
        HStack {
            Text("Assigned Trips")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            if !assignedTripsVM.assignedTrips.isEmpty {
                Text("\(assignedTripsVM.assignedTrips.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
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
                userLocationCoordinate: nil
            )
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private struct TripLocationSection: View {
        let trip: Trip
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                LocationRow(icon: "mappin.circle.fill", color: .blue, label: "From", value: trip.startLocation)
                LocationRow(icon: "mappin.circle.fill", color: .green, label: "To", value: trip.endLocation)
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
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
    }

    private struct TripDetailsSection: View {
        let trip: Trip
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Date and Time Section
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTripDate(trip.date))
                            .font(.subheadline.bold())
                        Text(formatTripTime(trip.time))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Vehicle Details Section
                HStack(spacing: 12) {
                    Image(systemName: "car.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.vehicleType)
                            .font(.subheadline.bold())
                        Text(trip.vehicleType == "Passenger Vehicle" ?
                             "\(trip.passengers ?? 0) passengers" :
                             "\(Int(trip.loadWeight ?? 0)) kg load")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        
        private func formatTripDate(_ date: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let dateObj = formatter.date(from: date) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "EEEE, MMM d"
                return displayFormatter.string(from: dateObj)
            }
            return date
        }
        
        private func formatTripTime(_ time: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let date = formatter.date(from: time) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "h:mm a"
                return displayFormatter.string(from: date)
            }
            return time
        }
    }

    private struct TripActionButton: View {
        let trip: Trip
        @Binding var state: TripCardState
        let maxX: CGFloat
        let authVM: AuthViewModel
        let gradientStart: Color
        let gradientEnd: Color
        let isToday: Bool
        let isClockedIn: Bool
        @Binding var showClockInAlert: Bool
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.2), lineWidth: 1)
                    )
                
                if isToday && !state.isDragCompleted {
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            colors: state.swipeOffset == 0 ? [.gray.opacity(0.2)] : [gradientStart, state.isDragCompleted ? gradientEnd : gradientStart],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "car.side.fill")
                                    .scaleEffect(x: -1, y: 1)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20))
                            }
                            .offset(x: state.swipeOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if isClockedIn {
                                            state.isSwiping = true
                                            state.swipeOffset = min(max(value.translation.width, 0), maxX)
                                        } else {
                                            showClockInAlert = true
                                        }
                                    }
                                    .onEnded { _ in
                                        if isClockedIn {
                                            state.isSwiping = false
                                            if state.swipeOffset >= maxX - 10 {
                                                state.swipeOffset = maxX
                                                state.isDragCompleted = true
                                                state.isNavigating = true
                                            } else {
                                                withAnimation(.spring()) {
                                                    state.swipeOffset = 0
                                                }
                                            }
                                        }
                                    }
                            )
                            
                            Spacer()
                            
                            Text("Slide to Start Trip")
                                .font(.subheadline.bold())
                                .foregroundStyle(state.swipeOffset > 0 ? .white : .blue)
                        }
                        .padding(.horizontal, 8)
                    }
                } else {
                    Text(isToday ? "Trip Started" : "Scheduled for Later")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .frame(height: 56)
            .background(
                NavigationLink(
                    destination: PreInspectionView(
                        authVM: authVM,
                        dropoffLocation: trip.endLocation,
                        vehicleNumber: trip.vehicleId,
                        tripID: trip.id,
                        vehicleID: trip.vehicleId
                    ),
                    isActive: $state.isNavigating
                ) { EmptyView() }
            )
        }
    }

    private func isTripToday(_ trip: Trip) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return trip.date == today
    }

    private func tripCardView(for trip: Trip) -> some View {
        let mapData = tripMapData[trip.id] ?? TripMapData()
        let isToday = isTripToday(trip)
        
        // Initialize trip state if not present
        if tripStates[trip.id] == nil {
            tripStates[trip.id] = TripCardState()
        }
        
        return VStack(spacing: 0) {
            TripMapSection(mapData: mapData)
                .overlay(alignment: .topTrailing) {
                    if isToday {
                        Text("Today")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
            
            VStack(alignment: .leading, spacing: 12) {
                TripLocationSection(trip: trip)
                
                Divider()
                    .padding(.vertical, 8)
                
                TripDetailsSection(trip: trip)
                
                TripActionButton(
                    trip: trip,
                    state: Binding(
                        get: { tripStates[trip.id] ?? TripCardState() },
                        set: { tripStates[trip.id] = $0 }
                    ),
                    maxX: maxX,
                    authVM: authVM,
                    gradientStart: Self.gradientStart,
                    gradientEnd: Self.gradientEnd,
                    isToday: isToday,
                    isClockedIn: isClockedIn,
                    showClockInAlert: $showClockInAlert
                )
            }
            .padding(16)
            .frame(minHeight: 180) // Minimum height for details section, adjusted to match screenshot
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 320)
        .onAppear {
            fetchRoute(for: trip)
        }
    }
    
    private var tripsListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                let sortedTrips = assignedTripsVM.assignedTrips.sorted { trip1, trip2 in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    let dateTime1 = "\(trip1.date) \(trip1.time)"
                    let dateTime2 = "\(trip2.date) \(trip2.time)"
                    guard let date1 = formatter.date(from: dateTime1),
                          let date2 = formatter.date(from: dateTime2) else {
                        return false
                    }
                    return date1 > date2 // Latest first
                }
                ForEach(sortedTrips) { trip in
                    tripCardView(for: trip)
                }
            }
            .padding(.horizontal)
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
                        .foregroundStyle(.secondary)
                    Text("No trips assigned")
                        .font(.headline)
                        .foregroundStyle(.secondary)
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
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack {
                        headerSection
                        workingHoursSection
                        workingHoursContent
                        assignedTripSection
                    }
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
                .alert("Clock In Required", isPresented: $showClockInAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please clock in before starting a trip.")
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

struct DriverHomePage_Previews: PreviewProvider {
    static var previews: some View {
        DriverHomePage(
            authVM: AuthViewModel(),
            showProfile: .constant(false)
        )
        .preferredColorScheme(.light)
        .environmentObject(AuthViewModel())
    }
}
