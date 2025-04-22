import SwiftUI

struct MaintenanceDashboardView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        List {
            Text("Hi, \(authVM.user?.name ?? "")")
                .font(.largeTitle)
                .padding(.vertical)

            Section("Tasks") {
                DashboardCard(title: "Assigned Maintenance", systemImage: "wrench.and.screwdriver.fill")
                DashboardCard(title: "Log Completed Task", systemImage: "checkmark.seal.fill")
                DashboardCard(title: "Inventory", systemImage: "cube.box.fill")
                DashboardCard(title: "Work Orders", systemImage: "doc.fill")
                DashboardCard(title: "Messages", systemImage: "bubble.left.and.bubble.right.fill")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Maintenance")
    }
}
