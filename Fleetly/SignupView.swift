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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.gray.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    Text("Driver Sign Up")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                .padding(.top, 40)

                // Form Fields
                VStack(spacing: 16) {
                    Group {
                        TextField("Name", text: $name)
                        TextField("Phone", text: $phone)
                            .keyboardType(.numberPad)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Password", text: $password)
                        TextField("Aadhar Number", text: $aadhar)
                        TextField("License Number", text: $license)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // Error Message
                if let error = error {
                    Text(error)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Sign Up Button
                Button(action: signup) {
                    Text("Sign Up")
                        .font(.system(.headline, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
                .padding(.horizontal, 24)
                .disabled(fieldsEmpty)

                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(.body, design: .rounded))
            }
        }
    }
    
    private var fieldsEmpty: Bool {
        name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty || aadhar.isEmpty || license.isEmpty
    }
    
    private func signup() {
        authVM.signupDriver(
            name: name,
            email: email,
            phone: phone,
            password: password,
            aadharNumber: aadhar,
            licenseNumber: license
        ) { err in
            self.error = err
        }
    }
}
