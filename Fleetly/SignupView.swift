import SwiftUI

struct SignupView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var aadhar = ""
    @State private var license = ""
    @State private var error: String?

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Phone", text: $phone)
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            TextField("Aadhar Number", text: $aadhar)
            TextField("License Number", text: $license)

            Button("Sign Up") {
                authVM.signupDriver(name: name,
                                    email: email,
                                    phone: phone,
                                    password: password,
                                    aadharNumber: aadhar,
                                    licenseNumber: license) { err in
                    self.error = err
                }
            }

            if let error = error {
                Text(error).foregroundColor(.red)
            }
        }
    }
}
