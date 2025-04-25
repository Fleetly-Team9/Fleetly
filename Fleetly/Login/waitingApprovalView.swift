
import SwiftUI
struct WaitingApprovalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.badge.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .foregroundStyle(.blue)
            
            Text("Waiting for Approval")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text("Your account is pending approval from the manager.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Got it")
            {
                dismiss()
            }
            .font(.system(.headline, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding()
            .background(.blue)
            .foregroundColor(.white)
            .buttonBorderShape(.capsule)
        }
        .padding()
    }
}
