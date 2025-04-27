import SwiftUI
struct DriverDashboardView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        List {
            Text("Hello, \(authVM.user?.name ?? "")")
                .font(.largeTitle)
                .padding(.vertical)

        
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Driver")
    }
}
