/*import SwiftUI
import FirebaseFirestore

class AssignedTripsViewModel: ObservableObject {
    @Published var assignedTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var knownTripIDs = Set<String>()
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

                // Ensure we are using `Trip` type and initialize an empty array properly
                var updatedTrips: [Trip] = []  // Correct initialization of an array of Trip instances

                // Loop through documents and parse them into Trip instances
                for doc in snap.documents {
                    if let trip = Trip.from(document: doc) {
                        updatedTrips.append(trip)
                    }
                }

                // Update the assignedTrips property on the main thread
                DispatchQueue.main.async {
                    self.assignedTrips = updatedTrips
                }

                // Handle added document changes and notifications
                for change in snap.documentChanges where change.type == .added {
                    guard let newTrip = Trip.from(document: change.document) else { continue }
                    let id = newTrip.id
                    if !self.knownTripIDs.contains(id) {
                        if !self.isInitialLoad {
                            NotificationManager.shared.scheduleNewTripNotification(trip: newTrip)
                        }
                        self.knownTripIDs.insert(id)
                    }
                }

                if self.isInitialLoad {
                    self.isInitialLoad = false
                }
            }
    }
}
*/

import SwiftUI
import FirebaseFirestore

class AssignedTripsViewModel: ObservableObject {
    @Published var assignedTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var knownTripIDs = Set<String>()
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

                // Ensure we are using `Trip` type and initialize an empty array properly
                var updatedTrips: [Trip] = []  // Correct initialization of an array of Trip instances

                // Loop through documents and parse them into Trip instances
                for doc in snap.documents {
                    if let trip = Trip.from(document: doc) {
                        updatedTrips.append(trip)
                    }
                }

                // Update the assignedTrips property on the main thread
                DispatchQueue.main.async {
                    self.assignedTrips = updatedTrips
                }

                // Handle added document changes and notifications
                for change in snap.documentChanges where change.type == .added {
                    guard let newTrip = Trip.from(document: change.document) else { continue }
                    let id = newTrip.id
                    if !self.knownTripIDs.contains(id) {
                        if !self.isInitialLoad {
                            NotificationManager.shared.scheduleNewTripNotification(trip: newTrip)
                        }
                        self.knownTripIDs.insert(id)
                    }
                }

                if self.isInitialLoad {
                    self.isInitialLoad = false
                }
            }
    }
}

