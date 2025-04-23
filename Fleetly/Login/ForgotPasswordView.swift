import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var resetSent = false
    @State private var error: String?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.1), .white],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 20)

                VStack(spacing: 16) {
                    Image(systemName: resetSent ? "envelope.circle.fill" : "key.horizontal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(resetSent ? .blue : .gray)

                    Text(resetSent ? "Check Your Inbox" : "Forgot Password?")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)

                    if resetSent {
                        Text("We've sent a password reset link to:")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text(email)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)

                        Button("Back to Sign In") {
                            dismiss()
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .padding(.top, 8)
                    } else {
                        Text("Enter your registered email address to receive a reset link.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .textFieldStyle(.plain)

                        if let error = error {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.system(.footnote, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button {
                            sendResetLink()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            } else {
                                Text("Send Reset Link")
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                        }
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                        .disabled(email.isEmpty || !email.contains("@") || isLoading)
                        .padding(.top, 8)
                    }
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.blue)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .navigationBarBackButtonHidden(true)
        }
    }

    private func sendResetLink() {
        isLoading = true
        error = nil
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    error = err.localizedDescription
                } else {
                    resetSent = true
                }
            }
        }
    }
}
