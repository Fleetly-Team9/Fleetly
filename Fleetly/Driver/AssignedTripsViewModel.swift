import SwiftUI
import FirebaseFirestore
class AssignedTripsViewModel: ObservableObject {
  @Published var assignedTrips: [Trip] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private var db = Firestore.firestore()
  private var listener: ListenerRegistration?
  
  // 🔑 track what we've already seen
  private var knownTripIDs = Set<String>()
  // 🔑 skip notifications on first load
  private var isInitialLoad = true

  deinit {
    listener?.remove()
  }

  func startListening(driverId: String) {
    isLoading = true
    listener = db.collection("trips")
      .whereField("driverId", isEqualTo: driverId)
      .whereField("status", isEqualTo: "assigned")
      .addSnapshotListener { [weak self] snapshot, error in
        guard let self = self else { return }
        self.isLoading = false

        if let err = error {
          self.errorMessage = "Error listening for trips: \(err.localizedDescription)"
          return
        }
        guard let snap = snapshot else { return }

        var updatedTrips = [Trip]()
        for doc in snap.documents {
          if let trip = Trip.from(document: doc) {
            updatedTrips.append(trip)
          }
        }

        // Sort or whatever you need
        DispatchQueue.main.async {
          self.assignedTrips = updatedTrips
        }

        // Now handle notifications *only* after initial load
        for change in snap.documentChanges where change.type == .added {
          guard let newTrip = Trip.from(document: change.document) else { continue }
          let id = newTrip.id
          // If it’s truly brand new (we haven’t seen it before)
          if !self.knownTripIDs.contains(id) {
            if !self.isInitialLoad {
              NotificationManager.shared.scheduleNewTripNotification(trip: newTrip)
            }
            self.knownTripIDs.insert(id)
          }
        }
        // Once we’ve processed the first snapshot, turn off the “squelch”
        if self.isInitialLoad {
          self.isInitialLoad = false
        }
      }
  }
}

extension Trip {
    static func from(document: DocumentSnapshot) -> Trip? {
        let data = document.data() ?? [:]
        guard
            let id          = data["id"]           as? String,
            let driverId    = data["driverId"]     as? String,
            let vehicleId   = data["vehicleId"]    as? String,
            let startLoc    = data["startLocation"]as? String,
            let endLoc      = data["endLocation"]  as? String,
            let dateStr     = data["date"]         as? String,
            let timeStr     = data["time"]         as? String,
            let startTs     = (data["startTime"]   as? Timestamp)?.dateValue(),
            let statusStr   = data["status"]       as? String,
            let status      = Trip.TripStatus(rawValue: statusStr),
            let vehicleType = data["vehicleType"]  as? String
        else { return nil }
        
        return Trip(
            id: id,
            driverId: driverId,
            vehicleId: vehicleId,
            startLocation: startLoc,
            endLocation: endLoc,
            date: dateStr,
            time: timeStr,
            startTime: startTs,
            endTime: (data["endTime"] as? Timestamp)?.dateValue(),
            status: status,
            vehicleType: vehicleType,
            passengers: data["passengers"] as? Int,
            loadWeight: data["loadWeight"] as? Double
        )
    }
}
