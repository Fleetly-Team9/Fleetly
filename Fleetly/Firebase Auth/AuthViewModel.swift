import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false

    private let service = FirebaseService.shared

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
    func signupDriver(name: String,
                      email: String,
                      phone: String,
                      password: String,
                      aadharNumber: String,
                      licenseNumber: String,
                      completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { res, err in
            if let err = err {
                completion(err.localizedDescription); return
            }
            guard let uid = res?.user.uid else {
                completion("No UID after signup"); return
            }
            let user = User(
                id: uid,
                name: name,
                email: email,
                phone: phone,
                role: "driver",
                drivingLicenseNumber: licenseNumber,
                aadharNumber: aadharNumber,
                drivingLicenseDocUrl: "",
                aadharDocUrl: ""
            )
            self.service.saveUser(user) { err in
                if let err = err {
                    completion(err.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        self.user = user
                        self.isLoggedIn = true
                    }
                    completion(nil)
                }
            }
        }
    }
}
