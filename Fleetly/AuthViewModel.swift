import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false

    private let service = FirebaseService.shared

    func login(email: String,
               password: String,
               role: String,
               completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { res, err in
            if let err = err {
                completion(err.localizedDescription); return
            }
            guard let uid = res?.user.uid else {
                completion("No UID after login"); return
            }
            // Fetch user by document ID = uid
            self.service.fetchUser(id: uid) { result in
                switch result {
                case .success(let u) where u.role == role:
                    DispatchQueue.main.async {
                        self.user = u
                        self.isLoggedIn = true
                    }
                    completion(nil)
                case .success:
                    completion("Role mismatch.")
                case .failure(let e):
                    completion(e.localizedDescription)
                }
            }
        }
    }

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
