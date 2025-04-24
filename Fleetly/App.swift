import SwiftUI
import Firebase

@main
struct FMSApp: App {
    @StateObject private var authVM = AuthViewModel()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if authVM.isLoggedIn, let user = authVM.user {
                    switch user.role {
                    case "manager":     MainTabView()
                    case "driver":      DriverDashboardView(authVM: authVM)
                    case "maintenance": MaintenanceDashboardView(authVM: authVM)
                    default:            Text("Unknown role").foregroundColor(.red)
                    }
                } else {
                    LoginView(authVM: authVM)
                }
            }
        }
    }
}
