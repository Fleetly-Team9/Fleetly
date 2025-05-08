import SwiftUI
import Firebase

@main
struct FMSApp: App {
    @StateObject private var authVM = AuthViewModel()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        FirebaseApp.configure()
        NotificationManager.shared.requestAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            //NavigationView {
            if authVM.isLoading {
                // Show branded loading screen
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "car.front.waves.up.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.cyan)
                        
                        Text("Fleetly")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
            } else if authVM.isLoggedIn, let user = authVM.user {
                switch user.role {
                case "manager":     MainTabView(authVM: authVM)
                case "driver":      MainView(authVM: authVM)
                case "maintenance": ContentView()
                default:            Text("Unknown role").foregroundColor(.red)
                }
            } else {
                LoginView(authVM: authVM)
            }
            //}
            //}
        }
    }
}
