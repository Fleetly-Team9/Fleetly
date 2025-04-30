import Foundation
import _PhotosUI_SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false
    @Published var isSigningUp = false
    @Published var showWaitingApproval = false
    @Published var isLoading = true  // Add loading state
    // MFA / OTP state:
    @Published var isWaitingForOTP = false
    @Published var otpError: String?
    private var verificationID: String?
     var pendingUser: User?
    @Published var showRejectionSheet = false
    @Published var pendingEmail: String?
    private var pendingPassword: String?
    private let service = FirebaseService.shared
    private let db = Firestore.firestore()

    init() {
        // Enable persistence
        do {
            try Auth.auth().useUserAccessGroup(nil)
        } catch {
            print("Error enabling persistence: \(error.localizedDescription)")
        }
        
        // Check for existing session
        if let currentUser = Auth.auth().currentUser {
            self.service.fetchUser(id: currentUser.uid) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let user):
                    if user.isApproved ?? false {
                        DispatchQueue.main.async {
                            self.user = user
                            self.isLoggedIn = true
                            self.isLoading = false  // Set loading to false after session check
                        }
                    } else {
                        // If user is not approved, sign them out
                        try? Auth.auth().signOut()
                        DispatchQueue.main.async {
                            self.isLoading = false  // Set loading to false after session check
                        }
                    }
                case .failure:
                    // If we can't fetch user data, sign them out
                    try? Auth.auth().signOut()
                    DispatchQueue.main.async {
                        self.isLoading = false  // Set loading to false after session check
                    }
                }
            }
        } else {
            // No current user, set loading to false immediately
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    /// Email/password login → fetch User → send OTP
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        // First, check if the credentials are valid without signing in
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
            
            // Sign out immediately since we don't want to be logged in yet
            do {
                try Auth.auth().signOut()
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
            
            // Store password temporarily for OTP verification
            self.pendingPassword = password
            
            // Fetch user document
            self.service.fetchUser(id: uid) { result in
                switch result {
                case .success(let user):
                    // Check if user is approved
                    if !(user.isApproved ?? false) {
                        // Show waiting approval state
                        self.pendingUser = user
                        self.showWaitingApproval = true
                        completion(nil)
                    } else {
                        // SIMULATOR BYPASS
                        if self.isSimulator {
                            // For simulator, sign in and set user
                            Auth.auth().signIn(withEmail: email, password: password) { _, _ in }
                            self.user = user
                            self.isLoggedIn = true
                            completion(nil)
                            return
                        }
                        
                        // Normal login flow
                        self.pendingUser = user
                        self.sendOTP(to: user.email) { error in
                            if let error = error {
                                completion(error)
                            } else {
                                self.isWaitingForOTP = true
                                completion(nil)
                            }
                        }
                    }
                case .failure(let error):
                    if let nsError = error as? NSError, nsError.code == 404 {
                        self.showRejectionSheet = true
                        completion(nil) // No error passed to completion
                    } else {
                        completion(error.localizedDescription)
                    }
                }
            }
        }
    }
    func signOutAndDelete() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in.")
            return
        }
        
        user.delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
                return
            }
            
            do {
                try Auth.auth().signOut()
                self.user = nil
                self.isLoggedIn = false
                self.pendingUser = nil
                self.showRejectionSheet = false
                self.showWaitingApproval = false
                self.isWaitingForOTP = false
            } catch {
                print("Error signing out: \(error.localizedDescription)")
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
 
     var isSimulator: Bool {
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
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
                                                // Simulator bypass
                                                if self.isSimulator {
                                                    // Bypass OTP flow
                                                    completion(nil)
                                                } else {
                                                    // Normal OTP flow
                                                    self.sendOTP(to: email) { error in
                                                        completion(error)
                                                    }
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
    //got it button, try in phone,
    func logout(){
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isLoggedIn = false
            self.pendingUser = nil
            self.showRejectionSheet = false
            self.showWaitingApproval = false
            self.isWaitingForOTP = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
       
}
extension AuthViewModel {
    // For login flow
    func verifyLoginOTP(code: String, completion: @escaping (Bool, String?) -> Void) {
        if isSimulator {
            // Auto-approve for simulator
            self.user = self.pendingUser
            self.isLoggedIn = true
            self.isWaitingForOTP = false
            completion(true, nil)
            return
        }
        
        guard let email = pendingUser?.email,
              let password = pendingPassword else {
            completion(false, "No email or password found for verification")
            return
        }
        
        Task {
            do {
                _ = try await supabase.auth.verifyOTP(
                    email: email,
                    token: code,
                    type: .email
                )
                
                // After OTP verification, sign in to Firebase
                Auth.auth().signIn(withEmail: email, password: password) { [weak self] res, err in
                    guard let self = self else { return }
                    
                    if let err = err {
                        DispatchQueue.main.async {
                            completion(false, err.localizedDescription)
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.user = self.pendingUser
                        self.isLoggedIn = true
                        self.isWaitingForOTP = false
                        self.pendingPassword = nil // Clear the stored password
                        completion(true, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // For signup flow
    func verifySignupOTP(code: String, completion: @escaping (Bool, String?) -> Void) {
        if isSimulator {
                    // Auto-approve for simulator
                    completion(true, nil)
                    return
                }
        guard let email = pendingEmail else {
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
}
