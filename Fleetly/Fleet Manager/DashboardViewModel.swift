import SwiftUI
import FirebaseFirestore
import CoreLocation
import UserNotifications

struct GeofenceDeviation: Identifiable {
    let id: String
    let tripId: String
    let vehicleId: String
    let driverId: String
    let distance: Double
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let vehicleNumber: String
    let driverName: String
    
    var formattedTripId: String {
        String(tripId.prefix(6))
    }
}

class DashboardViewModel: ObservableObject {
    @Published var totalVehicles: Int = 0
    @Published var maintenanceVehicles: Int = 0
    @Published var activeTickets: Int = 0
    @Published var pendingMaintenanceTasks: Int = 0
    @Published var recentDeviations: [GeofenceDeviation] = []
    
    private let db = Firestore.firestore()
    private var totalListener: ListenerRegistration?
    private var maintenanceListener: ListenerRegistration?
    private var ticketsListener: ListenerRegistration?
    private var maintenanceTasksListener: ListenerRegistration?
    private var deviationsListener: ListenerRegistration?
    private var lastDeviationTimestamp: Date? {
        get {
            UserDefaults.standard.object(forKey: "lastDeviationTimestamp") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastDeviationTimestamp")
        }
    }

    init() {
        requestNotificationPermission()
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
    
    private func scheduleDeviationNotification(for deviation: GeofenceDeviation) {
        let content = UNMutableNotificationContent()
        content.title = "Route Deviation Detected"
        content.body = "\(deviation.driverName) deviated from route in \(deviation.vehicleNumber) by \(String(format: "%.1f", deviation.distance))m"
        content.sound = .default
        
        // Create a unique identifier for this notification
        let identifier = "deviation-\(deviation.id)"
        
        // Create the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchVehicleStats() {
        // Remove existing listeners to avoid duplicates
        totalListener?.remove()
        maintenanceListener?.remove()
        ticketsListener?.remove()
        maintenanceTasksListener?.remove()

        // Real-time listener for total vehicles
        totalListener = db.collection("vehicles").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching total vehicles: \(error.localizedDescription)")
                return
            }
            let totalCount = snapshot?.documents.count ?? 0
            DispatchQueue.main.async {
                self.totalVehicles = totalCount
            }
        }

        // Real-time listener for vehicles in maintenance
        maintenanceListener = db.collection("vehicles")
            .whereField("status", isEqualTo: "In Maintenance")
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching maintenance vehicles: \(error.localizedDescription)")
                    return
                }
                let maintenanceCount = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.maintenanceVehicles = maintenanceCount
                }
            }
            
        // Real-time listener for active tickets (open or in progress)
        ticketsListener = db.collection("tickets")
            .whereField("status", in: ["Open", "In Progress"])
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching active tickets: \(error.localizedDescription)")
                    return
                }
                let activeCount = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.activeTickets = activeCount
                }
            }
            
        // Real-time listener for pending maintenance tasks
        maintenanceTasksListener = db.collection("maintenance_tasks")
            .whereField("status", in:["in_progress", "pending"])
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("Error fetching pending maintenance tasks: \(error.localizedDescription)")
                    return
                }
                let pendingCount = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.pendingMaintenanceTasks = pendingCount
                }
            }
    }
    
    func fetchRecentDeviations() {
        // Remove existing listener to avoid duplicates
        deviationsListener?.remove()
        
        // Real-time listener for recent geofence deviations
        deviationsListener = db.collection("geofence_deviations")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching deviations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No deviations found")
                    return
                }
                
                let group = DispatchGroup()
                var newDeviations: [GeofenceDeviation] = []
                
                for document in documents {
                    group.enter()
                    
                    if let data = document.data() as? [String: Any],
                       let tripId = data["tripId"] as? String,
                       let vehicleId = data["vehicleId"] as? String,
                       let driverId = data["driverId"] as? String,
                       let distance = data["distance"] as? Double,
                       let latitude = data["latitude"] as? Double,
                       let longitude = data["longitude"] as? Double,
                       let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() {
                        
                        // Fetch vehicle number
                        let vehicleGroup = DispatchGroup()
                        var vehicleNumber = ""
                        var driverName = ""
                        
                        vehicleGroup.enter()
                        self.db.collection("vehicles").document(vehicleId).getDocument { vehicleDoc, vehicleError in
                            defer { vehicleGroup.leave() }
                            if let vehicleData = vehicleDoc?.data(),
                               let number = vehicleData["licensePlate"] as? String {
                                vehicleNumber = number
                            }
                        }
                        
                        vehicleGroup.enter()
                        self.db.collection("users").document(driverId).getDocument { driverDoc, driverError in
                            defer { vehicleGroup.leave() }
                            if let driverData = driverDoc?.data(),
                               let name = driverData["name"] as? String {
                                driverName = name
                            }
                        }
                        
                        vehicleGroup.notify(queue: .main) {
                            let deviation = GeofenceDeviation(
                                id: document.documentID,
                                tripId: tripId,
                                vehicleId: vehicleId,
                                driverId: driverId,
                                distance: distance,
                                latitude: latitude,
                                longitude: longitude,
                                timestamp: timestamp,
                                vehicleNumber: vehicleNumber,
                                driverName: driverName
                            )
                            newDeviations.append(deviation)
                            
                            // Only trigger notification if this is a new deviation
                            if let lastTimestamp = self.lastDeviationTimestamp {
                                if timestamp > lastTimestamp {
                                    self.scheduleDeviationNotification(for: deviation)
                                }
                            }
                            
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    // Sort deviations by timestamp
                    newDeviations.sort { $0.timestamp > $1.timestamp }
                    
                    // Update the last deviation timestamp if we have new deviations
                    if let firstDeviation = newDeviations.first {
                        if self.lastDeviationTimestamp == nil || firstDeviation.timestamp > (self.lastDeviationTimestamp ?? Date.distantPast) {
                            self.lastDeviationTimestamp = firstDeviation.timestamp
                        }
                    }
                    
                    self.recentDeviations = newDeviations
                }
            }
    }

    deinit {
        // Clean up listeners when ViewModel is deallocated
        totalListener?.remove()
        maintenanceListener?.remove()
        ticketsListener?.remove()
        maintenanceTasksListener?.remove()
        deviationsListener?.remove()
    }
} 