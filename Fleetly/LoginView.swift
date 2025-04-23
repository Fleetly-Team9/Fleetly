import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var role = "manager"
    @State private var error: String?
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [.gray.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App Logo/Title
                VStack(spacing: 12) {
                    Image(systemName: "car.front.waves.up.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.cyan)
                    Text("FleetX")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 60)
                
                // Login Form
                VStack(spacing: 16) {
                    // Email Field
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Role Picker
                    
                    
                    // Forgot Password
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
                
                // Login Button
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
                
                // Sign Up Link (for drivers only)
                
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 24)
                
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignupView(authVM: authVM) // Assuming SignupView is styled similarly
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private func login() {
        isLoading = true
        authVM.login(email: email, password: password, role: role) { err in
            DispatchQueue.main.async {
                self.error = err
                self.isLoading = false
            }
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var resetSent = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.gray.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                if resetSent {
                    // Success Message
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        
                        Text("Reset Email Sent")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        
                        Text("We've sent a password reset link to \(email). Please check your inbox.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Back to Sign In") {
                            dismiss()
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                    }
                    .padding(.horizontal, 40)
                } else {
                    // Form
                    VStack(spacing: 20) {
                        Text("Enter your email to receive a password reset link")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button("Send Reset Link") {
                            requestReset()
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(email.isEmpty || !email.contains("@") || isLoading)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                }
            }
        }
    }
    
    private func requestReset() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            resetSent = true
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authVM: AuthViewModel())
    }
}
