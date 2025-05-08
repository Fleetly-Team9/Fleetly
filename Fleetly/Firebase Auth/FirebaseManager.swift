import Foundation
import CoreLocation
import Firebase
import FirebaseFirestore
import FirebaseStorage
//Firebase Manager for driver attendence and pre Inspection
struct ClockEvent: Codable {
    let type: String
    let timestamp: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case type
        case timestamp
    }
}

struct AttendanceRecord: Codable {
    @DocumentID var id: String?
    let driverId: String
    let date: String
    let clockInTime: Timestamp
    let clockEvents: [ClockEvent]
    let totalWorkedSeconds: Int
    let lastUpdated: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case driverId
        case date
        case clockInTime
        case clockEvents
        case totalWorkedSeconds
        case lastUpdated
    }
}

struct InspectionRecord: Codable {
    @DocumentID var id: String? // Will be the vehicleNumber (e.g., "KA1234")
    let driverID: String
    let timestamp: Timestamp
    let overallCheckStatus: String
    let imageURLs: [String]
    let defects: [String: Bool] // Updated to store booleans
    let Remarks: [String: String] // New map for remarks
    let needsMaintence: Bool
    let photoURL: String
    let tripID: String
    let vehicleID: String
    let mileage: Double? // Added mileage field
    
    enum CodingKeys: String, CodingKey {
        case driverID = "driverID"
        case timestamp
        case overallCheckStatus
        case imageURLs
        case defects
        case Remarks
        case needsMaintence
        case photoURL
        case tripID
        case vehicleID
        case mileage // Added to CodingKeys
    }
}


class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    func logRouteDeviation(tripId: String, vehicleId: String, driverId: String, distance: CLLocationDistance, location: CLLocation, timestamp: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        let deviationData: [String: Any] = [
            "tripId": tripId,
            "vehicleId": vehicleId,
            "driverId": driverId,
            "distance": distance,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        db.collection("geofence_deviations").addDocument(data: deviationData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func attendanceCollection(for driverId: String) -> CollectionReference {
        return db.collection("users").document(driverId).collection("attendance")
    }
    
    private func tripsCollection() -> CollectionReference {
        return db.collection("trips")
    }
    
    private func preinspectionCollection(for tripId: String) -> CollectionReference {
        return tripsCollection().document(tripId).collection("preinspection")
    }
    
    private func postinspectionCollection(for tripId: String) -> CollectionReference {
            return tripsCollection().document(tripId).collection("postinspection")
        }
    
    private func tripChargesCollection(for tripId: String) -> CollectionReference {
        return tripsCollection().document(tripId).collection("trip_charges")
    }
    
    private func inspectionCollection(for driverId: String) -> CollectionReference {
        return db.collection("driver").document(driverId).collection("inspection")
    }
    
    private func dateCollection(for driverId: String, date: String) -> CollectionReference {
        return inspectionCollection(for: driverId).document(date).collection("vehicles")
    }
    
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func compressImage(_ image: UIImage) -> Data? {
        // Compress and resize the image
        let maxDimension: CGFloat = 1200 // Maximum dimension for the image
        let compressionQuality: CGFloat = 0.5 // Compression quality (0.0 to 1.0)
        
        // Calculate new size while maintaining aspect ratio
        let originalSize = image.size
        let widthRatio = maxDimension / originalSize.width
        let heightRatio = maxDimension / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
        
        // Create compressed image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let compressedImage = resizedImage else {
            return nil
        }
        
        return compressedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    private func uploadImages(_ images: [UIImage], driverId: String, date: String, vehicleNumber: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let storageRef = storage.reference()
        var imageURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?
        
        for (index, image) in images.enumerated() {
            guard let imageData = compressImage(image) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
                return
            }
            
            let imagePath = "inspections/\(driverId)/\(date)/\(vehicleNumber)/image_\(index + 1).jpg"
            let imageRef = storageRef.child(imagePath)
            
            dispatchGroup.enter()
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    uploadError = error
                    dispatchGroup.leave()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        uploadError = error
                        dispatchGroup.leave()
                        return
                    }
                    
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = uploadError {
                completion(.failure(error))
            } else {
                completion(.success(imageURLs))
            }
        }
    }
    
    func recordClockEvent(driverId: String, type: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let dateString = currentDateString()
        let timestamp = Timestamp(date: Date())
        let clockEvent = ClockEvent(type: type, timestamp: timestamp)
        
        let docRef = attendanceCollection(for: driverId).document(dateString)
        
        docRef.getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.db.runTransaction { (transaction, errorPointer) -> Any? in
                var snapshotData: AttendanceRecord?
                do {
                    if snapshot?.exists == true {
                        snapshotData = try snapshot?.data(as: AttendanceRecord.self)
                    } else {
                        snapshotData = nil
                    }
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                
                var newRecord: AttendanceRecord
                var updatedEvents: [ClockEvent]
                var updatedTotalSeconds: Int
                
                if let existingRecord = snapshotData {
                    updatedEvents = existingRecord.clockEvents + [clockEvent]
                    updatedTotalSeconds = existingRecord.totalWorkedSeconds
                    
                    if type == "clockOut", let lastClockIn = updatedEvents.last(where: { $0.type == "clockIn" }) {
                        let lastClockInDate = lastClockIn.timestamp.dateValue()
                        let clockOutDate = timestamp.dateValue()
                        let secondsSinceLastClockIn = Int(clockOutDate.timeIntervalSince(lastClockInDate))
                        updatedTotalSeconds += secondsSinceLastClockIn
                    }
                    
                    newRecord = AttendanceRecord(
                        id: dateString,
                        driverId: driverId,
                        date: dateString,
                        clockInTime: existingRecord.clockInTime,
                        clockEvents: updatedEvents,
                        totalWorkedSeconds: updatedTotalSeconds,
                        lastUpdated: timestamp
                    )
                } else {
                    updatedEvents = [clockEvent]
                    updatedTotalSeconds = 0
                    
                    newRecord = AttendanceRecord(
                        id: dateString,
                        driverId: driverId,
                        date: dateString,
                        clockInTime: timestamp,
                        clockEvents: updatedEvents,
                        totalWorkedSeconds: updatedTotalSeconds,
                        lastUpdated: timestamp
                    )
                }
                
                do {
                    try transaction.setData(from: newRecord, forDocument: docRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                
                return nil
            } completion: { (object, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func fetchAttendanceRecord(driverId: String, date: String, completion: @escaping (Result<AttendanceRecord?, Error>) -> Void) {
        let docRef = attendanceCollection(for: driverId).document(date)
        
        docRef.getDocument { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            do {
                if snapshot?.exists == true {
                    let record = try snapshot?.data(as: AttendanceRecord.self)
                    completion(.success(record))
                } else {
                    completion(.success(nil))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchTodayWorkedTime(driverId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let dateString = currentDateString()
        
        fetchAttendanceRecord(driverId: driverId, date: dateString) { result in
            switch result {
            case .success(let record):
                let totalSeconds = record?.totalWorkedSeconds ?? 0
                completion(.success(totalSeconds))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func recordInspection(
        driverId: String,
        tyrePressureRemarks: String,
        brakeRemarks: String,
        oilCheck: Bool,
        hornCheck: Bool,
        clutchCheck: Bool,
        airbagsCheck: Bool,
        physicalDamageCheck: Bool,
        tyrePressureCheck: Bool,
        brakesCheck: Bool,
        indicatorsCheck: Bool,
        overallCheckStatus: String,
        images: [UIImage],
        vehicleNumber: String, // Used only as document ID
        date: String,
        tripId: String,
        vehicleID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let timestamp = Timestamp(date: Date())
        
        uploadImages(images, driverId: driverId, date: date, vehicleNumber: vehicleNumber) { result in
            switch result {
            case .success(let imageURLs):
                let photoURL = imageURLs.first ?? ""
                
                // Consolidate boolean checks into defects map
                let defects: [String: Bool] = [
                    "Oil": oilCheck,
                    "Horns": hornCheck,
                    "Clutch": clutchCheck,
                    "Airbags": airbagsCheck,
                    "PhysicalDamage": physicalDamageCheck,
                    "TyrePressure": tyrePressureCheck,
                    "Brakes": brakesCheck,
                    "Indicators": indicatorsCheck
                ]
                
                // Create remarks map
                let remarks: [String: String] = [
                    "TyrePressure": tyrePressureRemarks.isEmpty ? "No issues" : tyrePressureRemarks,
                    "Brakes": brakeRemarks.isEmpty ? "No issues" : brakeRemarks
                ]
                
                // Set needsMaintence based on overallCheckStatus
                let needsMaintence: Bool
                switch overallCheckStatus {
                case "Verified":
                    needsMaintence = false
                case "Raise Ticket":
                    needsMaintence = true
                default:
                    needsMaintence = false // Default to false for unexpected values
                }
                
                let inspectionRecord = InspectionRecord(
                    id: vehicleNumber, // Used as document ID
                    driverID: driverId,
                    timestamp: timestamp,
                    overallCheckStatus: overallCheckStatus,
                    imageURLs: imageURLs,
                    defects: defects,
                    Remarks: remarks,
                    needsMaintence: needsMaintence,
                    photoURL: photoURL,
                    tripID: tripId,
                    vehicleID: vehicleID,
                    mileage: nil
                )
                
                let preinspectionDocRef = self.preinspectionCollection(for: tripId).document(vehicleNumber)
                
                do {
                    try preinspectionDocRef.setData(from: inspectionRecord) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func recordPostInspection(
            driverId: String,
            tyrePressureRemarks: String,
            brakeRemarks: String,
            oilCheck: Bool,
            hornCheck: Bool,
            clutchCheck: Bool,
            airbagsCheck: Bool,
            physicalDamageCheck: Bool,
            tyrePressureCheck: Bool,
            brakesCheck: Bool,
            indicatorsCheck: Bool,
            mileage: Double?,
            overallCheckStatus: String,
            images: [UIImage],
            vehicleNumber: String,
            date: String,
            tripId: String,
            vehicleID: String,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            let timestamp = Timestamp(date: Date())
            
            uploadImages(images, driverId: driverId, date: date, vehicleNumber: vehicleNumber) { result in
                switch result {
                case .success(let imageURLs):
                    let photoURL = imageURLs.first ?? ""
                    
                    let defects: [String: Bool] = [
                        "Oil": oilCheck,
                        "Horns": hornCheck,
                        "Clutch": clutchCheck,
                        "Airbags": airbagsCheck,
                        "PhysicalDamage": physicalDamageCheck,
                        "TyrePressure": tyrePressureCheck,
                        "Brakes": brakesCheck,
                        "Indicators": indicatorsCheck
                    ]
                    
                    let remarks: [String: String] = [
                        "TyrePressure": tyrePressureRemarks.isEmpty ? "No issues" : tyrePressureRemarks,
                        "Brakes": brakeRemarks.isEmpty ? "No issues" : brakeRemarks
                    ]
                    
                    let needsMaintence: Bool
                    switch overallCheckStatus {
                    case "Verified":
                        needsMaintence = false
                    case "Raise Ticket":
                        needsMaintence = true
                    default:
                        needsMaintence = false
                    }
                    
                    let inspectionRecord = InspectionRecord(
                        id: vehicleNumber,
                        driverID: driverId,
                        timestamp: timestamp,
                        overallCheckStatus: overallCheckStatus,
                        imageURLs: imageURLs,
                        defects: defects,
                        Remarks: remarks,
                        needsMaintence: needsMaintence,
                        photoURL: photoURL,
                        tripID: tripId,
                        vehicleID: vehicleID,
                        mileage: mileage
                    )
                    let postinspectionDocRef = self.postinspectionCollection(for: tripId).document(vehicleNumber)
                    
                    do {
                        try postinspectionDocRef.setData(from: inspectionRecord) { error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            // Update the trip status to "completed"
                            let tripDocRef = self.tripsCollection().document(tripId)
                            tripDocRef.updateData(["status": "completed",
                                                   "endTime" : Timestamp(date:Date())
                                                  ]) { error in
                                if let error = error {
                                    completion(.failure(error))
                                } else {
                                    completion(.success(()))
                                }
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
    
    func fetchLatestInspection(driverId: String, tripId: String, completion: @escaping (Result<InspectionRecord?, Error>) -> Void) {
        preinspectionCollection(for: tripId)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let doc = snapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    let record = try doc.data(as: InspectionRecord.self)
                    completion(.success(record))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    // New function to save trip charges (Misc, fuelLog, tollFees)
    func saveTripCharges(
        tripId: String,
        misc: Double,
        fuelLog: Double,
        tollFees: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let docRef = tripChargesCollection(for: tripId).document("charges")
        
        let incidental = misc + fuelLog + tollFees
        
        let data: [String: Any] = [
            "Misc": misc,
            "fuelLog": fuelLog,
            "tollFees": tollFees,
            "Incidental": incidental
        ]
        
        docRef.setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // New function to save GoClicked timestamp
    func saveGoClicked(tripId: String, timestamp: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = tripChargesCollection(for: tripId).document("charges")
        
        // Format the timestamp as a String (ISO 8601 format)
        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: timestamp)
        
        let data: [String: Any] = [
            "GoClicked": timestampString
        ]
        
        docRef.setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // New function to save EndClicked timestamp
    func saveEndClicked(tripId: String, timestamp: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        let docRef = tripChargesCollection(for: tripId).document("charges")
        
        // Format the timestamp as a String (ISO 8601 format)
        let formatter = ISO8601DateFormatter()
        let timestampString = formatter.string(from: timestamp)
        
        let data: [String: Any] = [
            "EndClicked": timestampString
        ]
        
        docRef.setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
