import SwiftUI

struct RejectionView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Match Login/Signup gradient
            LinearGradient(
                colors: [.gray.opacity(0.1), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "xmark.octagon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                // Title
                Text("Access Denied")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)

                // Explanatory text
                Text("""
                Your driver request has been rejected. Please review your details and apply again.
                """)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Try Again button
                Button {
                    authVM.signOutAndDelete()
                    dismiss()
                    SignupView(authVM: authVM)
                 
                } label: {
                    Text("Try Again")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(24)
        }
    }
}
