import SwiftUI

struct LoginOTPView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var code = ""
    @State private var error: String?
    @State private var isVerifying = false
    @State private var countdown = 60
    @State private var timer: Timer?
    @State private var canResend = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.1), .white],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                Text("Enter Verification Code")
                    .font(.title2.bold())
                
                Text("We just sent a 6-digit code to your email.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("123456", text: $code)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .onChange(of: code) { newValue in
                        if newValue.count > 6 {
                            code = String(newValue.prefix(6))
                        }
                    }
                
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: verify) {
                    if isVerifying {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Verify Code")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
                .padding(.horizontal)
                .disabled(code.count != 6 || isVerifying)
                
                // Resend Code Button
                HStack {
                    Text("Didn't receive code?")
                        .foregroundColor(.secondary)
                    
                    Button(action: resendCode) {
                        if canResend {
                            Text("Resend")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        } else {
                            Text("Resend in \(countdown)s")
                                .foregroundColor(.gray)
                        }
                    }
                    .disabled(!canResend)
                }
                .font(.footnote)
                
                Spacer()
                
                Button("Cancel") {
                    timer?.invalidate()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onReceive(authVM.$isLoggedIn) { loggedIn in
            if loggedIn {
                timer?.invalidate()
                dismiss()
            }
        }
    }
    
    private func verify() {
        isVerifying = true
        error = nil
        authVM.verifyLoginOTP(code: code) { success, err in
            DispatchQueue.main.async {
                self.isVerifying = false
                if !success {
                    self.error = err
                }
            }
        }
    }
    
    private func resendCode() {
        if let email = authVM.pendingUser?.email {
            countdown = 60
            canResend = false
            startCountdown()
            
            authVM.sendOTP(to: email) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.error = error
                        self.timer?.invalidate()
                        self.canResend = true
                    }
                }
            }
        }
    }
    
    private func startCountdown() {
        timer?.invalidate()
        canResend = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                canResend = true
                timer?.invalidate()
            }
        }
    }
}
