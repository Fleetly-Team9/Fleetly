import Foundation
import _PhotosUI_SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false
    @Published var isSigningUp = false

    private let service = FirebaseService.shared
    private let db = Firestore.firestore()
    /// Sign in, then fetch your User document (which contains the role).
    func login(email: String,
               password: String,
               completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { res, err in
            if let err = err {
                completion(err.localizedDescription)
                return
            }
            guard let uid = res?.user.uid else {
                completion("No UID after login")
                return
            }
            self.service.fetchUser(id: uid) { result in
                switch result {
                case .success(let u):
                    DispatchQueue.main.async {
                        self.user = u
                        self.isLoggedIn = true
                    }
                    completion(nil)
                case .failure(let e):
                    completion(e.localizedDescription)
                }
            }
        }
    }

    /// Driver-only signup remains unchanged
    func signupDriver(
           firstName: String,
           lastName: String,
           gender: String,
           age: Int,
           disability: String,
           phone: String,
           email: String,
           password: String,
           aadharNumber: String,
           licenseNumber: String,
           aadharPhotoItem: PhotosPickerItem?,
           licensePhotoItem: PhotosPickerItem?,
           completion: @escaping (String?) -> Void
       ) {
           isSigningUp = true

           Auth.auth().createUser(withEmail: email, password: password) { [weak self] res, err in
               guard let self = self else { return }
               if let err = err {
                   self.isSigningUp = false
                   return completion(err.localizedDescription)
               }
               guard let firebaseUser = res?.user else {
                   self.isSigningUp = false
                   return completion("Unexpected signup error")
               }

               // 1. Send email verification
               firebaseUser.sendEmailVerification { _ in }

               let uid = firebaseUser.uid
               let fullName = "\(firstName) \(lastName)"

               // 2. Upload Aadhar photo
               let aadharPath = "users/\(uid)/aadhar.jpg"
               self.service.uploadPhoto(item: aadharPhotoItem, path: aadharPath) { result in
                   switch result {
                   case .failure(let err):
                       self.isSigningUp = false
                       return completion("Aadhar upload failed: \(err.localizedDescription)")
                   case .success(let aadharURL):
                       // 3. Upload License photo
                       let licPath = "users/\(uid)/license.jpg"
                       self.service.uploadPhoto(item: licensePhotoItem, path: licPath) { licResult in
                           switch licResult {
                           case .failure(let err):
                               self.isSigningUp = false
                               return completion("License upload failed: \(err.localizedDescription)")
                           case .success(let licenseURL):
                               // 4. Build User model and save to Firestore
                               let user = User(
                                   id: uid,
                                   name: fullName,
                                   email: email,
                                   phone: phone,
                                   role: "driver",
                                   gender: gender,
                                   age: age,
                                   disability: disability,
                                   aadharNumber: aadharNumber,
                                   drivingLicenseNumber: licenseNumber,
                                   aadharDocUrl: aadharURL.isEmpty ? nil : aadharURL,
                                   licenseDocUrl: licenseURL.isEmpty ? nil : licenseURL
                               )
                               do {
                                   var data = try Firestore.Encoder().encode(user)
                                   data["uid"] = nil
                                   self.db.collection("users").document(uid)
                                       .setData(data) { err in
                                           DispatchQueue.main.async {
                                               self.isSigningUp = false
                                               if let err = err {
                                                   completion(err.localizedDescription)
                                               } else {
                                                   completion(nil)
                                               }
                                           }
                                       }
                               } catch {
                                   self.isSigningUp = false
                                   completion("Encoding user failed")
                               }
                           }
                       }
                   }
               }
           }
       }
    
}
