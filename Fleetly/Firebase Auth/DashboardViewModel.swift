//
//  DashboardViewModel.swift
//  Fleetly
//
//  Created by admin40 on 25/04/25.
//

import SwiftUI
import FirebaseFirestore

class DashboardViewModel: ObservableObject {
    @Published var totalVehicles: Int = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func fetchTotalVehicles() {
        // Remove existing listener to avoid duplicates
        listener?.remove()

        // Add a real-time listener
        listener = db.collection("vehicles").addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error fetching total vehicles: \(error.localizedDescription)")
                return
            }
            // Get the count of documents in the vehicles collection
            if let count = snapshot?.documents.count {
                DispatchQueue.main.async {
                    self.totalVehicles = count
                }
            } else {
                print("No vehicles found")
                self.totalVehicles = 0
            }
        }
    }

    deinit {
        // Clean up listener when ViewModel is deallocated
        listener?.remove()
    }
}
