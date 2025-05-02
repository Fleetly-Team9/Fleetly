import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LogbookView: View {
    @StateObject private var viewModel = LogbookViewModel()
    @State private var selectedDate: Date = {
        // Set initial date to the current date (May 2, 2025)
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 5, day: 2)
        return calendar.date(from: components) ?? Date()
    }()
    @State private var isDatePickerVisible = false // State to toggle DatePicker visibility
    
    // Define the maximum selectable date (current date: May 2, 2025)
    private var maxDate: Date {
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 5, day: 2)
        return calendar.date(from: components) ?? Date()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Display the selected date at the top
                Text("Selected Date: \(formattedDate(selectedDate))")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 10)
                
                // Header with Calendar Picker Toggle
                HStack {
                    Text("Driver Logbook")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Button to toggle DatePicker visibility
                    Button(action: {
                        isDatePickerVisible.toggle()
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(.blue)
                            Text("Change Date")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // DatePicker (shown/hidden based on toggle)
                if isDatePickerVisible {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        in: ...maxDate, // Restrict to dates up to May 2, 2025
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onAppear {
                        print("DatePicker displayed with range: up to \(formattedDate(maxDate))")
                    }
                }
                
                // Driver List
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.drivers) { driver in
                            DriverCard(driver: driver)
                        }
                    }
                    .padding()
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if viewModel.drivers.isEmpty && !viewModel.isLoading {
                    Text("No drivers found for \(formattedDate(selectedDate)).")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedDate) { newDate in
                print("Selected date changed to: \(formattedDate(newDate))")
                isDatePickerVisible = false // Hide DatePicker after selection
                viewModel.fetchDrivers(for: newDate)
            }
            .onAppear {
                print("Initial date: \(formattedDate(selectedDate))")
                viewModel.fetchDrivers(for: selectedDate)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DriverCard: View {
    let driver: Driver
    
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            Circle()
                .fill(driver.wasPresent ? Color.green : Color.red)
                .frame(width: 12, height: 12)
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(driver.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 20) {
                    Text("Clock In: \(driver.clockIn ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Clock Out: \(driver.clockOut ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Total Worked: \(driver.totalWorkedMinutes) minutes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 10)
    }
}

struct Driver: Identifiable {
    let id: String
    let name: String
    let clockIn: String?
    let clockOut: String?
    let wasPresent: Bool
    let totalWorkedMinutes: Int
}

class LogbookViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    private let db = Firestore.firestore()
    
    func fetchDrivers(for date: Date) {
        isLoading = true
        drivers.removeAll()
        
        // Normalize the date to avoid timezone issues
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let normalizedDate = calendar.date(from: components) else {
            print("Error: Could not normalize date")
            self.isLoading = false
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: normalizedDate)
        print("Fetching data for date: \(dateString) (Normalized: \(normalizedDate))")
        
        // Fetch only users with role "driver"
        db.collection("users")
            .whereField("role", isEqualTo: "driver")
            .getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching drivers: \(error?.localizedDescription ?? "Unknown error")")
                self?.isLoading = false
                return
            }
            
            print("Fetched \(documents.count) drivers (role: 'driver') from /users collection")
            
            let group = DispatchGroup()
            
            for doc in documents {
                let userID = doc.documentID
                let name = doc.get("name") as? String ?? "Unknown"
                print("Driver ID: \(userID), Name: \(name), Role: \(doc.get("role") as? String ?? "N/A")")
                
                group.enter()
                // Fetch attendance data for the specific date
                let attendanceRef = self.db.collection("users").document(userID)
                    .collection("attendance").document(dateString)
                
                print("Querying attendance for driver \(userID) at path: /users/\(userID)/attendance/\(dateString)")
                
                attendanceRef.getDocument { (docSnapshot, error) in
                    if let error = error {
                        print("Error fetching attendance for driver \(userID) on \(dateString): \(error.localizedDescription)")
                        print("Possible issue: Check Firestore security rules or network connectivity")
                    } else if let docSnapshot = docSnapshot, docSnapshot.exists {
                        // Log all fields in the attendance document
                        print("Attendance document data for driver \(userID) on \(dateString): \(docSnapshot.data() ?? [:])")
                        
                        // Fetch totalWorkedSeconds directly from the attendance document
                        let totalWorkedSeconds = docSnapshot.get("totalWorkedSeconds") as? Int ?? 0
                        print("Driver \(userID) - totalWorkedSeconds: \(totalWorkedSeconds)")
                        let totalWorkedMinutes = totalWorkedSeconds / 60 // Convert to minutes
                        print("Driver \(userID) - totalWorkedMinutes: \(totalWorkedMinutes)")
                        let wasPresent = totalWorkedSeconds > 0
                        
                        // Fetch clockEvents as an array field from the attendance document
                        var clockIn: String?
                        var clockOut: String?
                        
                        if let clockEvents = docSnapshot.get("clockEvents") as? [[String: Any]] {
                            print("Found \(clockEvents.count) clockEvents entries for driver \(userID) on \(dateString):")
                            
                            // Variables to track earliest clockIn and latest clockOut
                            var earliestClockIn: (timestamp: Timestamp, formatted: String)?
                            var latestClockOut: (timestamp: Timestamp, formatted: String)?
                            
                            // Iterate through clockEvents array
                            for (index, event) in clockEvents.enumerated() {
                                print(" - Event \(index + 1): \(event)")
                                
                                guard let type = event["type"] as? String,
                                      let timestamp = event["timestamp"] as? Timestamp else {
                                    print("Driver \(userID) - Event \(index + 1): Missing 'type' or 'timestamp' field")
                                    continue
                                }
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "HH:mm"
                                let formattedTime = dateFormatter.string(from: timestamp.dateValue())
                                
                                if type == "clockIn" {
                                    print("Driver \(userID) - clockIn found: \(formattedTime) (Timestamp: \(timestamp.dateValue()))")
                                    let currentClockIn = (timestamp: timestamp, formatted: formattedTime)
                                    if earliestClockIn == nil || timestamp.dateValue() < earliestClockIn!.timestamp.dateValue() {
                                        earliestClockIn = currentClockIn
                                    }
                                } else if type == "clockOut" {
                                    print("Driver \(userID) - clockOut found: \(formattedTime) (Timestamp: \(timestamp.dateValue()))")
                                    let currentClockOut = (timestamp: timestamp, formatted: formattedTime)
                                    if latestClockOut == nil || timestamp.dateValue() > latestClockOut!.timestamp.dateValue() {
                                        latestClockOut = currentClockOut
                                    }
                                } else {
                                    print("Driver \(userID) - Event \(index + 1): Unknown type '\(type)'")
                                }
                            }
                            
                            // Set clockIn and clockOut based on earliest and latest times
                            clockIn = earliestClockIn?.formatted
                            clockOut = latestClockOut?.formatted
                            
                            if clockIn == nil {
                                print("Driver \(userID) - No clockIn events found in clockEvents")
                            }
                            if clockOut == nil {
                                print("Driver \(userID) - No clockOut events found in clockEvents")
                            }
                        } else {
                            print("Driver \(userID) - No clockEvents array found in document")
                        }
                        
                        let driver = Driver(
                            id: userID,
                            name: name,
                            clockIn: clockIn,
                            clockOut: clockOut,
                            wasPresent: wasPresent,
                            totalWorkedMinutes: totalWorkedMinutes
                        )
                        
                        // Log the constructed Driver object
                        print("Constructed Driver for driver \(userID): Name: \(driver.name), ClockIn: \(driver.clockIn ?? "N/A"), ClockOut: \(driver.clockOut ?? "N/A"), WasPresent: \(driver.wasPresent), TotalWorkedMinutes: \(driver.totalWorkedMinutes)")
                        
                        DispatchQueue.main.async {
                            self.drivers.append(driver)
                        }
                    } else {
                        print("Driver \(userID) - No attendance data found for \(dateString)")
                        // Create a Driver with no attendance data
                        let driver = Driver(
                            id: userID,
                            name: name,
                            clockIn: nil,
                            clockOut: nil,
                            wasPresent: false,
                            totalWorkedMinutes: 0
                        )
                        print("Constructed Driver for driver \(userID) (no attendance): Name: \(driver.name), ClockIn: \(driver.clockIn ?? "N/A"), ClockOut: \(driver.clockOut ?? "N/A"), WasPresent: \(driver.wasPresent), TotalWorkedMinutes: \(driver.totalWorkedMinutes)")
                        DispatchQueue.main.async {
                            self.drivers.append(driver)
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.isLoading = false
                // Sort drivers: present drivers first, then absent, both groups sorted by name
                self.drivers.sort { (driver1, driver2) -> Bool in
                    if driver1.wasPresent == driver2.wasPresent {
                        return driver1.name.lowercased() < driver2.name.lowercased()
                    }
                    return driver1.wasPresent && !driver2.wasPresent
                }
                print("Finished fetching drivers for \(dateString). Total drivers: \(self.drivers.count)")
                print("Sorted drivers: \(self.drivers.map { "\($0.name) (Present: \($0.wasPresent), Minutes: \($0.totalWorkedMinutes))" })")
            }
        }
    }
}

struct LogbookView_Previews: PreviewProvider {
    static var previews: some View {
        LogbookView()
    }
}
