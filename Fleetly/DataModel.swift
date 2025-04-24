import Foundation

struct User: Identifiable, Codable {
    let id: String                     // Firestore doc ID / Auth UID
    let name: String                   // firstName + " " + lastName
    let email: String
    let phone: String
    let role: String                   // always "driver" here
    let gender: String?
    let age: Int?
    let disability: String?
    let aadharNumber: String?
    let drivingLicenseNumber: String?
    let aadharDocUrl: String?          // Storage download URL
    let licenseDocUrl: String?         // Storage download URL

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case name, email, phone, role, gender, age, disability
        case aadharNumber, drivingLicenseNumber
        case aadharDocUrl, licenseDocUrl
    }
}
