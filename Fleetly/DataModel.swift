import Foundation

struct User: Identifiable, Codable,Equatable {
    var id: String                     // Firestore doc ID / Auth UID
    let name: String                   // firstName + " " + lastName
    let email: String
    let phone: String
    let role: String                   // always "driver" here
    let gender: String?
    let age: Int?
    let disability: String?
    let aadharNumber: String?
    let drivingLicenseNumber: String?
    var aadharDocUrl: String?          // Storage download URL
    var licenseDocUrl: String?
    var isApproved: Bool?              // New field for manager approval
    var isAvailable: Bool?
    // Default initializer with isApproved set to false
    init(id: String,
         name: String,
         email: String,
         phone: String,
         role: String,
         gender: String? = nil,
         age: Int? = nil,
         disability: String? = nil,
         aadharNumber: String? = nil,
         drivingLicenseNumber: String? = nil,
         aadharDocUrl: String? = nil,
         licenseDocUrl: String? = nil,
         isApproved: Bool? = false,
         isAvailable: Bool? = true) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.gender = gender
        self.age = age
        self.disability = disability
        self.aadharNumber = aadharNumber
        self.drivingLicenseNumber = drivingLicenseNumber
        self.aadharDocUrl = aadharDocUrl
        self.licenseDocUrl = licenseDocUrl
        self.isApproved = isApproved
        self.isAvailable = isAvailable
    }

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case name, email, phone, role, gender, age, disability
        case aadharNumber, drivingLicenseNumber
        case aadharDocUrl, licenseDocUrl
        case isApproved, isAvailable               // New coding key
    }
}
