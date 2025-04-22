import SwiftUI

struct ManagerDashboardView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        List {
            Text("Welcome, \(authVM.user?.name ?? "")")
                .font(.largeTitle)
                .padding(.vertical)

            Section("Quick Actions") {
                DashboardCard(title: "Vehicle Management", systemImage: "car.fill")
                DashboardCard(title: "User Management", systemImage: "person.3.fill")
                DashboardCard(title: "Maintenance Scheduling", systemImage: "calendar")
                DashboardCard(title: "Reports & Analytics", systemImage: "chart.bar.fill")
                DashboardCard(title: "Geofencing", systemImage: "mappin.and.ellipse")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Manager")
    }
}

struct DashboardCard: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 36, height: 36)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
