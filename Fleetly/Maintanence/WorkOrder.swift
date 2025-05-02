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

    // Computed property to convert expectedDelivery to Date for ScheduleView
    var completionDateAsDate: Date? {
        guard let expectedDelivery = expectedDelivery else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // e.g., "6:00 PM"
        if let time = formatter.date(from: expectedDelivery) {
            // Combine with the current date for comparison
            let calendar = Calendar.current
            let today = Date()
            let components = calendar.dateComponents([.year, .month, .day], from: today)
            var dateComponents = calendar.dateComponents([.hour, .minute], from: time)
            dateComponents.year = components.year
            dateComponents.month = components.month
            dateComponents.day = components.day
            return calendar.date(from: dateComponents)
        }
        return nil
    }

    // Equatable conformance
    static func == (lhs: WorkOrder, rhs: WorkOrder) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Message: Identifiable {
    let id: String // Changed to String to match Firestore
    let sender: String
    let time: String
    let content: String
}

struct InventoryItem: Identifiable {
    let id: String // Changed to String to match Firestore
    let name: String
    var units: Int
}
