import Foundation
import _PhotosUI_SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false
    @Published var isSigningUp = false

    // MFA / OTP state:
    @Published var isWaitingForOTP = false
    @Published var otpError: String?
    private var verificationID: String?
    private var pendingUser: User?

    private let service = FirebaseService.shared
    private let db = Firestore.firestore()

    /// Email/password login → fetch User → send OTP
    func login(email: String,
               password: String,
               completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] res, err in
            guard let self = self else { return }
            if let err = err {
                completion(err.localizedDescription)
                return
            }
            guard let uid = res?.user.uid else {
                completion("No UID after login")
                return
            }
            // Fetch full user document (so we get phone, role, etc.)
            self.service.fetchUser(id: uid) { result in
                switch result {
                case .success(let u):
                    // Hold user until OTP verified
                    self.pendingUser = u
                    // Kick off OTP to their phone
                    self.sendOTP(to: u.phone)
                    DispatchQueue.main.async {
                        self.isWaitingForOTP = true
                    }
                    completion(nil)
                case .failure(let e):
                    completion(e.localizedDescription)
                }
            }
        }
    }

    private func sendOTP(to phone: String) {
        PhoneAuthProvider.provider()
            .verifyPhoneNumber(phone, uiDelegate: nil) { [weak self] id, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.otpError = error.localizedDescription
                    } else {
                        self?.verificationID = id
                        self?.otpError = nil
                    }
                }
            }
    }

    /// Call this once user enters the code
    func verifyOTP(code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let id = verificationID else {
            completion(false, "No verification ID")
            return
        }
        let credential = PhoneAuthProvider.provider()
            .credential(withVerificationID: id, verificationCode: code)

        // Link the SMS credential to the existing session
        Auth.auth().currentUser?.link(with: credential) { [weak self] res, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else if let user = self?.pendingUser {
                    // OTP passed! finalize login
                    self?.user = user
                    self?.isLoggedIn = true
                    self?.isWaitingForOTP = false
                    completion(true, nil)
                } else {
                    completion(false, "Unknown error")
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
