import Foundation
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
    let driverId: String
    let vehicleNumber: String
    let timestamp: Timestamp
    let tyrePressureRemarks: String
    let brakeRemarks: String
    let oilCheck: Bool
    let hornCheck: Bool
    let clutchCheck: Bool
    let airbagsCheck: Bool
    let physicalDamageCheck: Bool
    let tyrePressureCheck: Bool
    let brakesCheck: Bool
    let indicatorsCheck: Bool
    let overallCheckStatus: String
    let imageURLs: [String]
    
    enum CodingKeys: String, CodingKey {
        case driverId
        case vehicleNumber
        case timestamp
        case tyrePressureRemarks
        case brakeRemarks
        case oilCheck
        case hornCheck
        case clutchCheck
        case airbagsCheck
        case physicalDamageCheck
        case tyrePressureCheck
        case brakesCheck
        case indicatorsCheck
        case overallCheckStatus
        case imageURLs
    }
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    private func attendanceCollection(for driverId: String) -> CollectionReference {
        return db.collection("users").document(driverId).collection("attendance")
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
    
    private func uploadImages(_ images: [UIImage], driverId: String, date: String, vehicleNumber: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let storageRef = storage.reference()
        var imageURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        var uploadError: Error?
        
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])))
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
        vehicleNumber: String,
        date: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let timestamp = Timestamp(date: Date())
        
        uploadImages(images, driverId: driverId, date: date, vehicleNumber: vehicleNumber) { result in
            switch result {
            case .success(let imageURLs):
                let inspectionRecord = InspectionRecord(
                    id: vehicleNumber,
                    driverId: driverId,
                    vehicleNumber: vehicleNumber,
                    timestamp: timestamp,
                    tyrePressureRemarks: tyrePressureRemarks,
                    brakeRemarks: brakeRemarks,
                    oilCheck: oilCheck,
                    hornCheck: hornCheck,
                    clutchCheck: clutchCheck,
                    airbagsCheck: airbagsCheck,
                    physicalDamageCheck: physicalDamageCheck,
                    tyrePressureCheck: tyrePressureCheck,
                    brakesCheck: brakesCheck,
                    indicatorsCheck: indicatorsCheck,
                    overallCheckStatus: overallCheckStatus,
                    imageURLs: imageURLs
                )
                
                let dateDocRef = self.inspectionCollection(for: driverId).document(date)
                let vehicleDocRef = dateDocRef.collection(vehicleNumber).document("details")
                
                do {
                    try vehicleDocRef.setData(from: inspectionRecord) { error in
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
    
    func fetchLatestInspection(driverId: String, completion: @escaping (Result<InspectionRecord?, Error>) -> Void) {
        inspectionCollection(for: driverId)
            .order(by: "id", descending: true)
            .limit(to: 1)
            .getDocuments { (dateSnapshot, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let dateDoc = dateSnapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }
                
                let date = dateDoc.documentID
                
                let vehicleCollection = self.inspectionCollection(for: driverId).document(date)
                
                vehicleCollection.collection("KA1234").document("details")
                    .getDocument { (vehicleSnapshot, error) in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        do {
                            if vehicleSnapshot?.exists == true {
                                let record = try vehicleSnapshot?.data(as: InspectionRecord.self)
                                completion(.success(record))
                            } else {
                                completion(.success(nil))
                            }
                        } catch {
                            completion(.failure(error))
                        }
                    }
            }
    }
}
