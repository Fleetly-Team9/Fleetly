import SwiftUI

struct RoleSelectionView: View {
    @State private var selectedRole: UserRole? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Select Your Role")
                    .font(.largeTitle.bold())
                    .padding(.top, 60)

                ForEach(UserRole.allCases) { role in
                    Button(action: {
                        selectedRole = role
                    }) {
                        Text(role.rawValue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: Binding<Bool>(
                get: { selectedRole != nil },
                set: { if !$0 { selectedRole = nil } }
            )) {
                if let role = selectedRole {
                    AppRouter.view(for: role)
                }
            }
        }
    }
}
