import SwiftUI

struct OTPVerificationView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @State private var error: String?
    @State private var isVerifying = false

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

                Text("We just sent a 6-digit code to your phone.")
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

                Spacer()

                Button("Cancel") {
                    // allow cancel back to Login
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .onReceive(authVM.$isLoggedIn) { loggedIn in
            if loggedIn {
                dismiss()
            }
        }
    }

    private func verify() {
        isVerifying = true
        error = nil
        authVM.verifyOTP(code: code) { success, err in
            DispatchQueue.main.async {
                self.isVerifying = false
                if !success {
                    self.error = err
                }
                // on success, isLoggedIn toggles and this sheet auto-dismisses
            }
        }
    }
}
