import SwiftUI

struct AppRouter {
    static func view(for role: UserRole) -> some View {
        switch role {
        case .fleetManager:
            return AnyView(FleetManagerFlow())
        case .driver:
            return AnyView(DriverFlow())
        case .maintenance:
            return AnyView(MaintenanceFlow())
        }
    }
}
