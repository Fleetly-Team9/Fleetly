//
//  Ride.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//
import Foundation
import FirebaseFirestore
/*struct Ride: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let startTime: Date
    let endTime: Date
    let startLocation: String
    let endLocation: String
    let mileage: Int
    let maintenanceStatus: MaintenanceStatus
    let vehicleNumber: String
    let vehicleModel: String
    let preInspectionImage: String?
    let postInspectionImage: String?
    let fuelExpense: Double
    let tollExpense: Double
    let miscExpense: Double
    
    // Computed property for charges
    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }
    
    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }
    
    var tripDuration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
*/




// Struct for preinspection and postinspection data
/*struct Inspection: Codable {
    let remarks: Remarks
    let defects: Defects
    let driverID: String
    let imageURLs: [String]
    let needsMaintence: Bool
    let overallCheckStatus: String
    let photoURL: String
    let timestamp: Date
    let tripID: String
    let vehicleID: String
    let mileage: Double? // Only for postinspection

    struct Remarks: Codable {
        let brakes: String
        let tyrePressure: String

        enum CodingKeys: String, CodingKey {
            case brakes = "Brakes"
            case tyrePressure = "TyrePressure"
        }
    }

    struct Defects: Codable {
        let airbags: Bool
        let brakes: Bool
        let clutch: Bool
        let horns: Bool
        let indicators: Bool
        let oil: Bool
        let physicalDamage: Bool
        let tyrePressure: Bool

        enum CodingKeys: String, CodingKey {
            case airbags = "Airbags"
            case brakes = "Brakes"
            case clutch = "Clutch"
            case horns = "Horns"
            case indicators = "Indicators"
            case oil = "Oil"
            case physicalDamage = "PhysicalDamage"
            case tyrePressure = "TyrePressure"
        }
    }

    enum CodingKeys: String, CodingKey {
        case remarks = "Remarks"
        case defects
        case driverID
        case imageURLs
        case needsMaintence
        case overallCheckStatus
        case photoURL
        case timestamp
        case tripID
        case vehicleID
        case mileage
    }
}

// Struct for trip_charges data
struct TripCharges: Codable {
    let endClicked: String
    let goClicked: String
    let incidental: Double
    let misc: Double
    let fuelLog: Double
    let tollFees: Double

    enum CodingKeys: String, CodingKey {
        case endClicked = "EndClicked"
        case goClicked = "GoClicked"
        case incidental = "Incidental"
        case misc = "Misc"
        case fuelLog
        case tollFees
    }
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let passengers: Int
    let startLocation: String
    let startTime: Date
    let status: String
    let time: String
    let vehicleId: String
    let vehicleType: String
    var preInspection: Inspection? // To be fetched from subcollection
    var postInspection: Inspection? // To be fetched from subcollection
    var tripCharges: TripCharges? // To be fetched from subcollection

    // Computed properties to match the original Ride struct
    var date: Date {
        startTime // Use startTime as the date for filtering
    }

    var endTime: Date {
        postInspection?.timestamp ?? startTime // Use postinspection timestamp as endTime
    }

    var endLocation: String?{
        // Since endLocation isn't in Firestore, we can use a placeholder or fetch from elsewhere
        // For now, we'll return an empty string or fetch from another source if available
        nil
    }

    var mileage: Double {
        postInspection?.mileage ?? 0.0
    }

    var maintenanceStatus: MaintenanceStatus {
        MaintenanceStatus(rawValue: postInspection?.overallCheckStatus ?? "Raise Ticket") ?? .ticketRaised
    }

    var vehicleNumber: String {
        vehicleId // Use vehicleId as vehicleNumber
    }

    var vehicleModel: String {
        vehicleType // Use vehicleType as vehicleModel
    }

    var preInspectionImage: [String]? {
        preInspection?.imageURLs
    }

    var postInspectionImage: [String]? {
        postInspection?.imageURLs
    }

    var fuelExpense: Double {
        tripCharges?.fuelLog ?? 0.0
    }

    var tollExpense: Double {
        tripCharges?.tollFees ?? 0.0
    }

    var miscExpense: Double {
        tripCharges?.misc ?? 0.0
    }

    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }

    var tripDuration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case passengers
        case startLocation
        case startTime
        case status
        case time
        case vehicleId
        case vehicleType
    }
}
*/
/*import Foundation
import FirebaseFirestore

// Struct for preinspection and postinspection data
struct Inspection: Codable {
    let remarks: Remarks
    let defects: Defects
    let driverID: String
    let imageURLs: [String]
    let needsMaintence: Bool
    let overallCheckStatus: String
    let photoURL: String
    let timestamp: Date
    let tripID: String
    let vehicleID: String
    let mileage: Double?

    struct Remarks: Codable {
        let brakes: String
        let tyrePressure: String

        enum CodingKeys: String, CodingKey {
            case brakes = "Brakes"
            case tyrePressure = "TyrePressure"
        }
    }

    struct Defects: Codable {
        let airbags: Bool
        let brakes: Bool
        let clutch: Bool
        let horns: Bool
        let indicators: Bool
        let oil: Bool
        let physicalDamage: Bool
        let tyrePressure: Bool

        enum CodingKeys: String, CodingKey {
            case airbags = "Airbags"
            case brakes = "Brakes"
            case clutch = "Clutch"
            case horns = "Horns"
            case indicators = "Indicators"
            case oil = "Oil"
            case physicalDamage = "PhysicalDamage"
            case tyrePressure = "TyrePressure"
        }
    }

    enum CodingKeys: String, CodingKey {
        case remarks = "Remarks"
        case defects
        case driverID
        case imageURLs
        case needsMaintence
        case overallCheckStatus
        case photoURL
        case timestamp
        case tripID
        case vehicleID
        case mileage
    }
}

// Struct for trip_charges data
struct TripCharges: Codable {
    let endClicked: String
    let goClicked: String
    let incidental: Double
    let misc: Double
    let fuelLog: Double
    let tollFees: Double

    enum CodingKeys: String, CodingKey {
        case endClicked = "EndClicked"
        case goClicked = "GoClicked"
        case incidental = "Incidental"
        case misc = "Misc"
        case fuelLog
        case tollFees
    }
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String // Added driverId field
    let passengers: Int
    let startLocation: String
    let endLocation: String
    let startTime: Date
    let endTime: Date? // Added as a stored property
    let status: String
    let time: String
    let vehicleId: String
    let vehicleType: String
    var preInspection: Inspection?
    var postInspection: Inspection?
    var tripCharges: TripCharges?

    var date: Date {
        startTime
    }

    var endTime: Date {
        postInspection?.timestamp ?? startTime
    }

    var mileage: Double {
        postInspection?.mileage ?? 0.0
    }

    var maintenanceStatus: MaintenanceStatus {
        MaintenanceStatus(rawValue: postInspection?.overallCheckStatus ?? "Raise Ticket") ?? .ticketRaised
    }

    var vehicleNumber: String {
        vehicleId
    }

    var vehicleModel: String {
        vehicleType
    }

    var preInspectionImage: [String]? {
        preInspection?.imageURLs
    }

    var postInspectionImage: [String]? {
        postInspection?.imageURLs
    }

    var fuelExpense: Double {
        tripCharges?.fuelLog ?? 0.0
    }

    var tollExpense: Double {
        tripCharges?.tollFees ?? 0.0
    }

    var miscExpense: Double {
        tripCharges?.misc ?? 0.0
    }

    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }

    var tripDuration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case passengers
        case startLocation
        case endLocation
        case startTime
        case status
        case time
        case vehicleId
        case vehicleType
    }
}
*/
import Foundation
import FirebaseFirestore

// Struct for preinspection and postinspection data
/*struct Inspection: Codable {
    let remarks: Remarks
    let defects: Defects
    let driverID: String
    let imageURLs: [String]
    let needsMaintence: Bool
    let overallCheckStatus: String
    let photoURL: String
    let timestamp: Date
    let tripID: String
    let vehicleID: String
    let mileage: Double?

    struct Remarks: Codable {
        let brakes: String
        let tyrePressure: String

        enum CodingKeys: String, CodingKey {
            case brakes = "Brakes"
            case tyrePressure = "TyrePressure"
        }
    }

    struct Defects: Codable {
        let airbags: Bool
        let brakes: Bool
        let clutch: Bool
        let horns: Bool
        let indicators: Bool
        let oil: Bool
        let physicalDamage: Bool
        let tyrePressure: Bool

        enum CodingKeys: String, CodingKey {
            case airbags = "Airbags"
            case brakes = "Brakes"
            case clutch = "Clutch"
            case horns = "Horns"
            case indicators = "Indicators"
            case oil = "Oil"
            case physicalDamage = "PhysicalDamage"
            case tyrePressure = "TyrePressure"
        }
    }

    enum CodingKeys: String, CodingKey {
        case remarks = "Remarks"
        case defects
        case driverID
        case imageURLs
        case needsMaintence
        case overallCheckStatus
        case photoURL
        case timestamp
        case tripID
        case vehicleID
        case mileage
    }
}

// Struct for trip_charges data
struct TripCharges: Codable {
    let endClicked: String
    let goClicked: String
    let incidental: Double
    let misc: Double
    let fuelLog: Double
    let tollFees: Double

    enum CodingKeys: String, CodingKey {
        case endClicked = "EndClicked"
        case goClicked = "GoClicked"
        case incidental = "Incidental"
        case misc = "Misc"
        case fuelLog
        case tollFees
    }
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String
    let passengers: Int
    let startLocation: String
    let endLocation: String
    let startTime: Date
    let endTime: Date // Added as a stored property
    let status: String
    let time: String
    let vehicleId: String
    let vehicleType: String
    var preInspection: Inspection?
    var postInspection: Inspection?
    var tripCharges: TripCharges?

    var date: Date {
        startTime
    }

    var mileage: Double {
        postInspection?.mileage ?? 0.0
    }

    var maintenanceStatus: MaintenanceStatus {
        MaintenanceStatus(rawValue: postInspection?.overallCheckStatus ?? "Raise Ticket") ?? .ticketRaised
    }

    var vehicleNumber: String {
        vehicleId
    }

    var vehicleModel: String {
        vehicleType
    }

    var preInspectionImage: [String]? {
        preInspection?.imageURLs
    }

    var postInspectionImage: [String]? {
        postInspection?.imageURLs
    }

    var fuelExpense: Double {
        tripCharges?.fuelLog ?? 0.0
    }

    var tollExpense: Double {
        tripCharges?.tollFees ?? 0.0
    }

    var miscExpense: Double {
        tripCharges?.misc ?? 0.0
    }

    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }

    var tripDuration: String {
        let end = endTime ?? Date() // Use current time if endTime is nil
        let interval = end.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case passengers
        case startLocation
        case endLocation
        case startTime
        case endTime
        case status
        case time
        case vehicleId
        case vehicleType
    }
}
*/
/*import Foundation
import FirebaseFirestore

// Struct for preinspection and postinspection data
struct Inspection: Codable {
    let remarks: Remarks
    let defects: Defects
    let driverID: String
    let imageURLs: [String]
    let needsMaintence: Bool
    let overallCheckStatus: String
    let photoURL: String
    let timestamp: Date
    let tripID: String
    let vehicleID: String
    let mileage: Double?

    struct Remarks: Codable {
        let brakes: String
        let tyrePressure: String

        enum CodingKeys: String, CodingKey {
            case brakes = "Brakes"
            case tyrePressure = "TyrePressure"
        }
    }

    struct Defects: Codable {
        let airbags: Bool
        let brakes: Bool
        let clutch: Bool
        let horns: Bool
        let indicators: Bool
        let oil: Bool
        let physicalDamage: Bool
        let tyrePressure: Bool

        enum CodingKeys: String, CodingKey {
            case airbags = "Airbags"
            case brakes = "Brakes"
            case clutch = "Clutch"
            case horns = "Horns"
            case indicators = "Indicators"
            case oil = "Oil"
            case physicalDamage = "PhysicalDamage"
            case tyrePressure = "TyrePressure"
        }
    }

    enum CodingKeys: String, CodingKey {
        case remarks = "Remarks"
        case defects
        case driverID
        case imageURLs
        case needsMaintence
        case overallCheckStatus
        case photoURL
        case timestamp
        case tripID
        case vehicleID
        case mileage
    }
}

// Struct for trip_charges data
struct TripCharges: Codable {
    let endClicked: String
    let goClicked: String
    let incidental: Double
    let misc: Double
    let fuelLog: Double
    let tollFees: Double

    enum CodingKeys: String, CodingKey {
        case endClicked = "EndClicked"
        case goClicked = "GoClicked"
        case incidental = "Incidental"
        case misc = "Misc"
        case fuelLog
        case tollFees
    }
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String
    let passengers: Int
    let startLocation: String
    let endLocation: String
    let startTime: Date
    let endTime: Date // Non-optional, as rides are only displayed after completion
    let status: String
    let time: String
    let vehicleId: String
    let vehicleType: String
    var preInspection: Inspection?
    var postInspection: Inspection?
    var tripCharges: TripCharges?

    var date: Date {
        startTime
    }

    var mileage: Double {
        postInspection?.mileage ?? 0.0
    }

    var maintenanceStatus: MaintenanceStatus {
        MaintenanceStatus(rawValue: postInspection?.overallCheckStatus ?? "Raise Ticket") ?? .ticketRaised
    }

    var vehicleNumber: String {
        vehicleId
    }

    var vehicleModel: String {
        vehicleType
    }

    var preInspectionImage: [String]? {
        preInspection?.imageURLs
    }

    var postInspectionImage: [String]? {
        postInspection?.imageURLs
    }

    var fuelExpense: Double {
        tripCharges?.fuelLog ?? 0.0
    }

    var tollExpense: Double {
        tripCharges?.tollFees ?? 0.0
    }

    var miscExpense: Double {
        tripCharges?.misc ?? 0.0
    }

    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }

    var tripDuration: String {
        let interval = endTime.timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case passengers
        case startLocation
        case endLocation
        case startTime
        case endTime
        case status
        case time
        case vehicleId
        case vehicleType
        case preInspection
        case postInspection
        case tripCharges
    }
}
*/
import Foundation
import FirebaseFirestore

// Struct for preinspection and postinspection data
struct Inspection: Codable {
    let remarks: Remarks
    let defects: Defects
    let driverID: String
    let imageURLs: [String]
    let needsMaintence: Bool
    let overallCheckStatus: String
    let photoURL: String
    let timestamp: Date
    let tripID: String
    let vehicleID: String
    let mileage: Double?

    struct Remarks: Codable {
        let brakes: String
        let tyrePressure: String

        enum CodingKeys: String, CodingKey {
            case brakes = "Brakes"
            case tyrePressure = "TyrePressure"
        }
    }

    struct Defects: Codable {
        let airbags: Bool
        let brakes: Bool
        let clutch: Bool
        let horns: Bool
        let indicators: Bool
        let oil: Bool
        let physicalDamage: Bool
        let tyrePressure: Bool

        enum CodingKeys: String, CodingKey {
            case airbags = "Airbags"
            case brakes = "Brakes"
            case clutch = "Clutch"
            case horns = "Horns"
            case indicators = "Indicators"
            case oil = "Oil"
            case physicalDamage = "PhysicalDamage"
            case tyrePressure = "TyrePressure"
        }
    }

    enum CodingKeys: String, CodingKey {
        case remarks = "Remarks"
        case defects
        case driverID
        case imageURLs
        case needsMaintence
        case overallCheckStatus
        case photoURL
        case timestamp
        case tripID
        case vehicleID
        case mileage
    }
}

// Struct for trip_charges data
struct TripCharges: Codable {
    let endClicked: String?
    let goClicked: String?
    let incidental: Double
    let misc: Double
    let fuelLog: Double
    let tollFees: Double

    enum CodingKeys: String, CodingKey {
        case endClicked = "EndClicked"
        case goClicked = "GoClicked"
        case incidental = "Incidental"
        case misc = "Misc"
        case fuelLog
        case tollFees
    }
}

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String
    let passengers: Int
    let startLocation: String
    let endLocation: String
    let startTime: Date
    let endTime: Date // Non-optional, as rides are only displayed after completion
    let status: String
    let time: String
    let vehicleId: String
    let vehicleType: String
    var preInspection: Inspection?
    var postInspection: Inspection?
    var tripCharges: TripCharges?

    var date: Date {
        startTime
    }

    var mileage: Double {
        postInspection?.mileage ?? 0.0
    }

    var maintenanceStatus: MaintenanceStatus {
        MaintenanceStatus(rawValue: postInspection?.overallCheckStatus ?? "Raise Ticket") ?? .ticketRaised
    }

    var vehicleNumber: String {
        vehicleId
    }

    var vehicleModel: String {
        vehicleType
    }

    var preInspectionImage: [String]? {
        preInspection?.imageURLs
    }
    
    var postInspectionImage: [String]? {
        postInspection?.imageURLs // Fixed to use postInspection instead of preInspection
    }

    var fuelExpense: Double {
        tripCharges?.fuelLog ?? 0.0
    }

    var tollExpense: Double {
        tripCharges?.tollFees ?? 0.0
    }

    var miscExpense: Double {
        tripCharges?.misc ?? 0.0
    }

    var charges: Double {
        fuelExpense + tollExpense + miscExpense
    }
    

    

    var tripDuration: String {
            let interval = max(0, endTime.timeIntervalSince(startTime))
            let hours = Int(interval) / 3600
            let minutes = (Int(interval) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

    enum MaintenanceStatus: String, Codable {
        case verified = "Verified"
        case ticketRaised = "Raise Ticket"
    }
    
    

    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case passengers
        case startLocation
        case endLocation
        case startTime
        case endTime
        case status
        case time
        case vehicleId
        case vehicleType
        case preInspection
        case postInspection
        case tripCharges
    }
}
