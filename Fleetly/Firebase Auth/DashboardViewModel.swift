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
    @Published var activeTickets: Int = 0
    @Published var pendingMaintenanceTasks: Int = 0
    private let db = Firestore.firestore()
    private var totalListener: ListenerRegistration?
    private var maintenanceListener: ListenerRegistration?
    private var ticketsListener: ListenerRegistration?
    private var maintenanceTasksListener: ListenerRegistration?

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
            .whereField("status", in:["in_progress", "pending"])            .addSnapshotListener { (snapshot, error) in
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

    deinit {
        // Clean up listeners when ViewModel is deallocated
        totalListener?.remove()
        maintenanceListener?.remove()
        ticketsListener?.remove()
        maintenanceTasksListener?.remove()
    }
}
