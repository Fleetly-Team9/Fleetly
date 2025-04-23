import SwiftUI

struct MaintenanceDashboardView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        List {
            Text("Hi, \(authVM.user?.name ?? "")")
                .font(.largeTitle)
                .padding(.vertical)

         
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Maintenance")
    }
}
