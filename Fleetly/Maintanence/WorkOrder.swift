import SwiftUI

struct WorkOrder: Identifiable, Equatable {
    let id: Int
    let vehicleNumber: String
    let issue: String
    var status: String
    let expectedDelivery: String?
    var priority: Int = 0 // 0 = low, 1 = medium, 2 = high
    var parts: [String] = [] // Parts used
    var laborCost: Double? // Labor cost
    var issues: [String] = [] // List of issues to track

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
