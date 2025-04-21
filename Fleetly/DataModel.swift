enum UserRole: String, CaseIterable, Identifiable {
    case fleetManager = "Fleet Manager"
    case driver = "Driver"
    case maintenance = "Maintenance Personnel"

    var id: String { self.rawValue }
}
