import Foundation
import FirebaseFirestore

struct Trip: Identifiable, Codable{
    let id: String
    let driverId: String
    let vehicleId: String
    let startLocation: String
    let endLocation: String
    let date: String
    let time: String
    let startTime: Date
    let endTime: Date?
    let status: TripStatus
    let vehicleType: String
    let passengers: Int?
    let loadWeight: Double?
    let goClicked: String?
    let endClicked: String?

//    enum TripStatus: String, Codable, CaseIterable, Identifiable {
//        case assigned
//        case inProgress
//        case completed
//        case delayed
//        case cancelled
//
//        var id: String { self.rawValue }
//
//        var displayName: String {
//            switch self {
//            case .assigned: return "Assigned"
//            case .inProgress: return "In Progress"
//            case .completed: return "Completed"
//            case .delayed: return "Delayed"
//            case .cancelled: return "Cancelled"
//            }
//        }
//    }

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
            let status      = TripStatus(rawValue: statusStr),
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
            status: status,
            vehicleType: vehicleType,
            passengers: data["passengers"] as? Int,
            loadWeight: data["loadWeight"] as? Double,
            goClicked: data["goClicked"] as? String,
            endClicked: data["endClicked"] as? String
        )
    }

    // ✅ Custom initializer for creating new trips without endTime
    init(
        id: String,
        driverId: String,
        vehicleId: String,
        startLocation: String,
        endLocation: String,
        date: String,
        time: String,
        startTime: Date,
        status: TripStatus,
        vehicleType: String,
        passengers: Int?,
        loadWeight: Double?,
        goClicked: String?,
        endClicked: String?
    ) {
        self.id = id
        self.driverId = driverId
        self.vehicleId = vehicleId
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.date = date
        self.time = time
        self.startTime = startTime
        self.endTime = nil // <- Defaulted to nil at creation
        self.status = status
        self.vehicleType = vehicleType
        self.passengers = passengers
        self.loadWeight = loadWeight
        self.goClicked = goClicked
        self.endClicked = endClicked
    }
}
