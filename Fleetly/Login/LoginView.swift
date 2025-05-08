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
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.gray.opacity(0.1), .white],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer(minLength: 20)
                        
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
                        Button {
                            signIn()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            } else {
                                Text("Sign In")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Welcome Back")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .dismissKeyboard() // Apply keyboard dismissal at the root level
        }
    }

    // MARK: - Actions
    private func signIn() {
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
