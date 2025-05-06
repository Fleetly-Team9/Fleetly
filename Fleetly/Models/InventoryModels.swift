import Foundation

enum Inventory {
    struct Item: Identifiable, Codable {
        let id: String
        var name: String
        var units: Int
        var minUnits: Int
        var lastUpdated: Date
        var price: Double
        
        init(id: String = UUID().uuidString, name: String, units: Int, minUnits: Int = 5, lastUpdated: Date = Date(), price: Double = 0.0) {
            self.id = id
            self.name = name
            self.units = units
            self.minUnits = minUnits
            self.lastUpdated = lastUpdated
            self.price = price
        }
    }

    struct HistoryItem: Identifiable, Codable {
        let id: String
        let itemId: String
        let oldUnits: Int
        let newUnits: Int
        let changedBy: String
        let timestamp: Date
        
        var changeAmount: Int {
            return newUnits - oldUnits
        }
        
        var formattedTimestamp: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
    }

    struct MaintenanceCost: Identifiable, Codable {
        let id: String
        let taskId: String
        let partsUsed: [PartUsage]
        let laborCost: Double
        let otherCosts: [OtherCost]
        let totalCost: Double
        let timestamp: Date
        
        struct PartUsage: Codable {
            let partId: String
            let partName: String
            let quantity: Int
            let unitPrice: Double
            var totalPrice: Double {
                return Double(quantity) * unitPrice
            }
        }
        
        struct OtherCost: Codable {
            let description: String
            let amount: Double
        }
    }

    enum Error: Swift.Error {
        case invalidData
        case networkError
        case unauthorized
        case unknown
        
        var localizedDescription: String {
            switch self {
            case .invalidData:
                return "Invalid data provided"
            case .networkError:
                return "Network error occurred"
            case .unauthorized:
                return "Unauthorized access"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
} 