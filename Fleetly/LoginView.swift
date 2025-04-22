import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var role = "manager"
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Login").font(.largeTitle.bold())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Picker("Role", selection: $role) {
                Text("Manager").tag("manager")
                Text("Driver").tag("driver")
                Text("Maintenance").tag("maintenance")
            }
            .pickerStyle(SegmentedPickerStyle())

            Button("Login") {
                authVM.login(email: email, password: password, role: role) { err in
                    self.error = err
                }
            }
            .buttonStyle(.borderedProminent)

            if role == "driver" {
                NavigationLink("Sign Up as Driver", destination: SignupView(authVM: authVM))
            }

            if let error = error {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
    }
}
