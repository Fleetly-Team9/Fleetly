import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.gray.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo / Title
                VStack(spacing: 12) {
                    Image(systemName: "car.front.waves.up.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.cyan)
                    Text("FleetX")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 60)

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    if let error = error {
                        Text(error)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                // Sign In Button
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Sign In")
                            .font(.system(.headline, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
                .padding(.horizontal, 24)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Spacer()

                // Always offer Driver Sign Up
                HStack {
                    Text("New Driver?")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)

                    Button("Create Driver Account") {
                        showSignUp = true
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.blue)
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignupView(authVM: authVM)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        
    }

    private func login() {
        isLoading = true
        authVM.login(email: email, password: password) { err in
            DispatchQueue.main.async {
                self.error = err
                self.isLoading = false
            }
        }
    }
}

