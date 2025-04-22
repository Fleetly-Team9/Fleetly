import Foundation

struct User: Identifiable, Codable {
    // Now 'id' is the document ID and satisfies Identifiable
    let id: String
    let name: String
    let email: String
    let phone: String
    let role: String                     // "manager", "driver", "maintenance"
    let drivingLicenseNumber: String?
    let aadharNumber: String?
    let drivingLicenseDocUrl: String?
    let aadharDocUrl: String?

    // Map our 'id' property to Firestore field "uid"
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case name, email, phone, role
        case drivingLicenseNumber, aadharNumber
        case drivingLicenseDocUrl, aadharDocUrl
    }

    // Default initializer and Codable conformance suffice—no manual init needed.
}
