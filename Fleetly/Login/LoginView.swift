import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel

    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            // Background Gradient
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
                    Text("Fleetly")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 60)

                // MARK: - Login Form
                VStack(spacing: 16) {
                    // Email Field
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Forgot Password Link
                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    // Error Message
                    if let error = error {
                        Text(error)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                // MARK: - Sign In Button
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

                // MARK: - Driver Sign Up Link
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
        // MARK: - Sheets
        .sheet(isPresented: $showSignUp) {
            SignupView(authVM: authVM)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $authVM.isWaitingForOTP) {
            LoginOTPView(authVM: authVM)
        }
        .sheet(isPresented: $authVM.showWaitingApproval) {
                    WaitingApprovalView()
                }
        .sheet(isPresented: $authVM.showRejectionSheet) {
                    RejectionView(authVM: authVM)
                }
    }

    // MARK: - Actions
    private func login() {
        isLoading = true
        error = nil

        authVM.login(email: email, password: password) { err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    error = err
                }
                // If no error, OTP sheet is presented automatically via isWaitingForOTP
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authVM: AuthViewModel())
    }
}
