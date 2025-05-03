import SwiftUI

struct WorkOrder: Identifiable, Equatable {
    let id: String
    let vehicleNumber: String
    let issue: String
    var status: String
    let expectedDelivery: String?
    var priority: Int // 0 = Low, 1 = Medium, 2 = High
    var issues: [String] // List of issues to track
    var parts: [String] = [] // Parts used (optional for MaintenanceDetailView)
    var laborCost: Double? // Labor cost (optional for MaintenanceDetailView)

    // Equatable conformance
    static func == (lhs: WorkOrder, rhs: WorkOrder) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Message: Identifiable {
    let id: Int
    let sender: String
    let time: String
    let content: String
}

struct InventoryItem: Identifiable {
    let id: Int
    let name: String
    var units: Int
}
