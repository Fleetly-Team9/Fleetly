import SwiftUI
import MapKit

struct MainView: View {
    @ObservedObject var authVM: AuthViewModel
    var body: some View {
        TabView {
            DriverHomePage(authVM: authVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            PastRideContentView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
        }
    }
}

struct DriverHomePage: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var currentTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var isStopwatchRunning = false
    @State private var startTime: Date? = nil
    @State private var isNavigating = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var isClockedIn = false
    @State private var currentWorkOrderIndex: Int = 0
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiping: Bool = false
    @State private var isDragCompleted: Bool = false
    
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let hours = (0...12).map { $0 == 0 ? "0hr" : "\($0)hr\($0 == 1 ? "" : "s")" }
    
    let dropoffLocation = "Kolkata" // Define the drop-off location here
    let vehicleNumber: String = "KA6A1204"
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    

    static let darkGray = Color(red: 68/255, green: 6/255, blue: 52/255)
    static let lightGray = Color(red: 240/255, green: 242/255, blue: 245/255)
    static let highlightYellow = Color(red: 235/255, green: 64/255, blue: 52/255)
    static let todayGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let customBlue = Color(.systemBlue)
    static let gradientStart = Color(red: 74/255, green: 145/255, blue: 226/255)
    static let gradientEnd = Color(red: 80/255, green: 227/255, blue: 195/255)
    static let initialCapsuleColor = Color(.systemGray5)
    
    private var maxX: CGFloat {
        let capsuleWidth = 343.0
        let circleWidth = 53.0
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
            VStack {
                Text("Here's your schedule for today!")
                    .font(.system(size: 15, design: .default))
                    .foregroundStyle(Color.secondary)
                    .padding(.trailing, 100)
            }
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color.primary)
            }
            .offset(y: -40)
        }
    }
    
    private var workingHoursSection: some View {
        VStack {
            Text("Working Hours")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundStyle(Color.primary)
                .frame(width: 200, height: 50, alignment: .leading)
                .padding(.trailing, 150)
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
                    VStack(spacing: 5) {
                        ZStack {
                            Rectangle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 684, height: 12)
                                .padding(.horizontal, 10)
                            
                            // Moved progressWidth computation here
                            let progressWidth: CGFloat = {
                                let maxTime: TimeInterval = 12 * 3600
                                let progress = min(elapsedTime / maxTime, 1.0)
                                return 684 * progress
                            }()
                            
                            Rectangle()
                                .fill(Color.blue)
                                .border(Color.black)
                                .frame(width: progressWidth, height: 20)
                                .padding(.horizontal, 10)
                            
                            HStack(spacing: 0) {
                                ForEach(0..<12, id: \.self) { index in
                                    Spacer()
                                        .frame(width: 40 + 12)
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.5))
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
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundStyle(Color.primary)
                                    .frame(width: 40, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .frame(width: 343)
                
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
                                isClockedIn.toggle() // Revert the toggle on failure
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
    
    private var assignedTripSection: some View {
        VStack {
            VStack {
                Text("Assigned Trip")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundStyle(Color.primary)
                    .frame(width: 200, height: 50, alignment: .leading)
                    .padding(.trailing, 150)
                Spacer()
            }
            .padding(.bottom, 10)
            
            VStack {
                ZStack {
                    Map(coordinateRegion: $region)
                        .frame(width: 363, height: 380)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
                        .frame(width: 363, height: 210)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .padding(.top, 170)
                    
                    VStack {
                        Text("Vehicle Number: \(vehicleNumber)")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundStyle(Color.primary)
                            .padding(.trailing, 80)
                            .padding(.leading, 5)
                        Text("Model Name: Swift DZire")
                            .foregroundStyle(Color.primary)
                            .padding(.trailing, 140)
                            .padding(.leading, 5)
                        Text("Drop Location: \(dropoffLocation)")
                            .foregroundStyle(Color.primary)
                            .padding(.trailing, 150)
                        Text("Departure:\(currentTime, formatter: timeFormatter)")
                            .foregroundStyle(Color.primary)
                            .padding(.trailing, 170)
                            .padding(.leading, 5)
                        Text("ETA: 10:00 AM")
                            .foregroundStyle(Color.primary)
                            .padding(.trailing, 210)
                            .padding(.leading, 5)
                    }
                    .padding(.top, 110)
                    VStack {
                        VStack {
                            ZStack(alignment: .leading) {
                                NavigationLink(
                                    destination: PreInspectionView(authVM: authVM, dropoffLocation: dropoffLocation,vehicleNumber : vehicleNumber),
                                    isActive: $isNavigating,
                                    label: {
                                        LinearGradient(
                                            colors: swipeOffset == 0 ? [Color(.systemGray5), Color(.systemGray5)] : [
                                                Self.gradientStart,
                                                swipeOffset >= maxX - 10 || isDragCompleted ? Self.gradientEnd : Self.gradientStart
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .frame(width: 343, height: 55)
                                        .clipShape(Capsule())
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 27.5)
                                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                )
                                .buttonStyle(PlainButtonStyle())
                                
                                HStack(spacing: 0) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemBlue))
                                            .frame(width: 53, height: 53)
                                        Image(systemName: "car.side.fill")
                                            .scaleEffect(x: -1, y: 1)
                                            .foregroundStyle(Color(.systemBackground))
                                    }
                                    .offset(x: swipeOffset)
                                    .gesture(
                                        isDragCompleted ? nil : DragGesture()
                                            .onChanged { value in
                                                isSwiping = true
                                                let capsuleWidth = 343.0
                                                let circleWidth = 53.0
                                                let minX = 0.0
                                                let maxX = capsuleWidth - circleWidth
                                                let newOffset = max(value.translation.width, 0)
                                                swipeOffset = min(newOffset, maxX)
                                                print("swipeOffset: \(swipeOffset)")
                                            }
                                            .onEnded { _ in
                                                isSwiping = false
                                                let capsuleWidth = 343.0
                                                let circleWidth = 53.0
                                                let maxX = capsuleWidth - circleWidth
                                                if swipeOffset >= maxX - 10 {
                                                    currentWorkOrderIndex += 1
                                                    print("Get Ready action triggered! Current Work Order Index: \(currentWorkOrderIndex)")
                                                    swipeOffset = maxX
                                                    isDragCompleted = true
                                                    isNavigating = true
                                                } else {
                                                    swipeOffset = 0
                                                }
                                            }
                                    )
                                    Spacer()
                                    Text("Slide to get Ready")
                                        .font(.system(size: 18, weight: .semibold, design: .default))
                                        .foregroundColor(swipeOffset > 0 || isDragCompleted ? .white : Color(.systemBlue))
                                        .padding(.trailing, 120)
                                }
                                .frame(width: 343, height: 55)
                            }
                            .padding(.top, 140)
                        }
                    }
                    .padding(.top, 160)
                }
                Spacer()
            }
            .offset(y: -20)
        }
        .offset(y: -40)
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
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView(authVM: AuthViewModel())
                .previewDisplayName("Light Mode")
            
            MainView(authVM: AuthViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

