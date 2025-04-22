import SwiftUI

struct DriverDashboardView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        List {
            Text("Hello, \(authVM.user?.name ?? "")")
                .font(.largeTitle)
                .padding(.vertical)

            Section("Your Trips") {
                DashboardCard(title: "Start New Trip", systemImage: "play.circle.fill")
                DashboardCard(title: "My Trip History", systemImage: "clock.fill")
                DashboardCard(title: "Vehicle Inspection", systemImage: "wrench.fill")
                DashboardCard(title: "My Routes", systemImage: "map.fill")
                DashboardCard(title: "Messages", systemImage: "message.fill")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Driver")
    }
}
