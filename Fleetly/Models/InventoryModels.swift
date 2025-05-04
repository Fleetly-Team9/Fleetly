import Foundation

enum Inventory {
    struct Item: Identifiable, Codable {
        let id: String
        var name: String
        var units: Int
        var minUnits: Int
        var lastUpdated: Date
        
        init(id: String = UUID().uuidString, name: String, units: Int, minUnits: Int = 5, lastUpdated: Date = Date()) {
            self.id = id
            self.name = name
            self.units = units
            self.minUnits = minUnits
            self.lastUpdated = lastUpdated
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