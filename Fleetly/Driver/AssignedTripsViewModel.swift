import SwiftUI
import FirebaseFirestore

class AssignedTripsViewModel: ObservableObject {
    @Published var assignedTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    func fetchAssignedTrips(driverId: String) {
        isLoading = true
        
        db.collection("trips")
            .whereField("driverId", isEqualTo: driverId)
            .whereField("status", isEqualTo: "assigned")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                defer { self.isLoading = false }
                
                if let error = error {
                    self.errorMessage = "Error fetching trips: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                var loadedTrips: [Trip] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard
                        let id = data["id"] as? String,
                        let driverId = data["driverId"] as? String,
                        let vehicleId = data["vehicleId"] as? String,
                        let startLocation = data["startLocation"] as? String,
                        let endLocation = data["endLocation"] as? String,
                        let date = data["date"] as? String,
                        let time = data["time"] as? String,
                        let startTime = (data["startTime"] as? Timestamp)?.dateValue(),
                        let statusString = data["status"] as? String,
                        let status = Trip.TripStatus(rawValue: statusString),
                        let vehicleType = data["vehicleType"] as? String
                    else { continue }
                    
                    let endTime = (data["endTime"] as? Timestamp)?.dateValue()
                    let passengers = data["passengers"] as? Int
                    let loadWeight = data["loadWeight"] as? Double
                    
                    let trip = Trip(
                        id: id,
                        driverId: driverId,
                        vehicleId: vehicleId,
                        startLocation: startLocation,
                        endLocation: endLocation,
                        date: date,
                        time: time,
                        startTime: startTime,
                        endTime: endTime,
                        status: status,
                        vehicleType: vehicleType,
                        passengers: passengers,
                        loadWeight: loadWeight
                    )
                    
                    loadedTrips.append(trip)
                }
                
                DispatchQueue.main.async {
                    self.assignedTrips = loadedTrips
                }
            }
    }
} 