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
     var pendingUser: User?
    @Published var pendingEmail: String?
    private let service = FirebaseService.shared
    private let db = Firestore.firestore()

    /// Email/password login → fetch User → send OTP
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
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
          
          self.service.fetchUser(id: uid) { result in
            switch result {
            case .success(let user):
              self.pendingUser = user
              self.sendOTP(to: user.email) { error in
                DispatchQueue.main.async {
                  if let error = error {
                    completion(error)
                  } else {
                    self.isWaitingForOTP = true
                    completion(nil)
                  }
                }
              } 
            case .failure(let e):
              completion(e.localizedDescription)
            }
          }
        }
      }

      // MARK: - Send OTP via Supabase
       func sendOTP(to email: String, completion: @escaping (String?) -> Void) {
        Task {
          do {
            try await supabase.auth.signInWithOTP(
              email: email,
              redirectTo: nil,
              shouldCreateUser: true // Prevents auto-creation of users
            )
            completion(nil)
          } catch {
            completion(error.localizedDescription)
          }
        }
      }

      // MARK: - Verify OTP with Supabase
      func verifyOTP(code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let email = pendingUser?.email else {
          completion(false, "No email found for verification")
          return
        }
        
        Task {
          do {
            let session = try await supabase.auth.verifyOTP(
              email: email,
              token: code,
              type: .email
            )
            
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return }
              // OTP verified, finalize login
              self.user = self.pendingUser
              self.isLoggedIn = true
              self.isWaitingForOTP = false
              completion(true, nil)
            }
          } catch {
            DispatchQueue.main.async {
              completion(false, error.localizedDescription)
            }
          }
        }
      }
    func verifyOTP(email: String, code: String, completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                let session = try await supabase.auth.verifyOTP(
                    email: email,
                    token: code,
                    type: .email
                )
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
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

                let uid = firebaseUser.uid
                let fullName = "\(firstName) \(lastName)"
                self.pendingEmail = email
                // Upload Aadhar photo
                let aadharPath = "users/\(uid)/aadhar.jpg"
                self.service.uploadPhoto(item: aadharPhotoItem, path: aadharPath) { result in
                    switch result {
                    case .failure(let err):
                        self.isSigningUp = false
                        return completion("Aadhar upload failed: \(err.localizedDescription)")
                    case .success(let aadharURL):
                        // Upload License photo
                        let licPath = "users/\(uid)/license.jpg"
                        self.service.uploadPhoto(item: licensePhotoItem, path: licPath) { licResult in
                            switch licResult {
                            case .failure(let err):
                                self.isSigningUp = false
                                return completion("License upload failed: \(err.localizedDescription)")
                            case .success(let licenseURL):
                                // Build User model with isApproved field
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
                                    licenseDocUrl: licenseURL.isEmpty ? nil : licenseURL,
                                    isApproved: false
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
                                                    // Send OTP after successful signup
                                                    self.sendOTP(to: email) { error in
                                                        completion(error)
                                                    }
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
