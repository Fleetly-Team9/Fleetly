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
    @Published var maintenanceVehicles: Int = 0
    private let db = Firestore.firestore()
    private var totalListener: ListenerRegistration?
    private var maintenanceListener: ListenerRegistration?

    func fetchVehicleStats() {
        // Remove existing listeners to avoid duplicates
        totalListener?.remove()
        maintenanceListener?.remove()

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
    }

    deinit {
        // Clean up listeners when ViewModel is deallocated
        totalListener?.remove()
        maintenanceListener?.remove()
    }
}
