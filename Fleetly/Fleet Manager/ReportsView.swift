//
//  ReportsView.swift
//  Fleetly
//
//  Created by admin68 on 06/05/25.
//
import SwiftUI
import FirebaseFirestore
import PDFKit

// MARK: - Report Types
enum ReportType: String, CaseIterable {
    case tripReport = "Trip Report"
    case maintenanceReport = "Maintenance Report"
    case driverReport = "Driver Report"
    case vehicleReport = "Vehicle Report"
    case expenseReport = "Expense Report"
}

// MARK: - Report ViewModel
class ReportsViewModel: ObservableObject {
    @Published var selectedReportType: ReportType = .tripReport
    @Published var dateRange: ClosedRange<Date> = Calendar.current.date(byAdding: .month, value: -1, to: Date())!...Date()
    @Published var isLoading = false
    @Published var error: String?
    @Published var generatedPDF: Data?
    @Published var showPDF = false
    
    private let db = Firestore.firestore()
    
    func generateReport() {
        isLoading = true
        error = nil
        
        switch selectedReportType {
        case .tripReport:
            generateTripReport()
        case .maintenanceReport:
            generateMaintenanceReport()
        case .driverReport:
            generateDriverReport()
        case .vehicleReport:
            generateVehicleReport()
        case .expenseReport:
            generateExpenseReport()
        }
    }
    
    private func generateTripReport() {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        db.collection("trips")
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                let trips = snapshot?.documents.compactMap { document -> Trip? in
                    try? document.data(as: Trip.self)
                } ?? []
                
                // Generate PDF content
                let pdfContent = self.createTripReportContent(trips: trips)
                self.generatePDF(from: pdfContent)
            }
    }
    
    private func generateMaintenanceReport() {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        // Convert dates to strings in yyyy-MM-dd format for comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateStr = dateFormatter.string(from: startDate)
        let endDateStr = dateFormatter.string(from: endDate)
        
        db.collection("maintenance_tasks")
            .whereField("createdAt", isGreaterThanOrEqualTo: startDateStr)
            .whereField("createdAt", isLessThanOrEqualTo: endDateStr)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                // Create a dispatch group to handle async cost fetching
                let group = DispatchGroup()
                var tasksWithCosts: [(MaintenanceTask, Inventory.MaintenanceCost?)] = []
                
                if let documents = snapshot?.documents {
                    for document in documents {
                        if let task = try? document.data(as: MaintenanceTask.self) {
                            group.enter()
                            
                            // Fetch costs for this task
                            self.db.collection("maintenance_tasks")
                                .document(task.id)
                                .collection("costs")
                                .getDocuments { costsSnapshot, costsError in
                                    defer { group.leave() }
                                    
                                    if let costsDoc = costsSnapshot?.documents.first,
                                       let cost = try? costsDoc.data(as: Inventory.MaintenanceCost.self) {
                                        tasksWithCosts.append((task, cost))
                                    } else {
                                        tasksWithCosts.append((task, nil))
                                    }
                                }
                        }
                    }
                }
                
                // Wait for all cost fetches to complete
                group.notify(queue: .main) {
                    // Generate PDF content with all the data
                    let pdfContent = self.createMaintenanceReportContent(tasksWithCosts: tasksWithCosts)
                    self.generatePDF(from: pdfContent)
                }
            }
    }
    
    private func generateDriverReport() {
        // First, fetch all drivers
        db.collection("users")
            .whereField("role", isEqualTo: "driver")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.error = "No drivers found"
                    self.isLoading = false
                    return
                }
                
                // Robust parsing: fallback to minimal User if decoding fails
                let drivers: [User] = documents.map { document in
                    (try? document.data(as: User.self)) ?? User(
                        id: document.documentID,
                        name: (document.data()["name"] as? String) ?? "Unknown",
                        email: (document.data()["email"] as? String) ?? "",
                        phone: (document.data()["phone"] as? String) ?? "",
                        role: (document.data()["role"] as? String) ?? "driver"
                    )
                }
                
                // Create a dispatch group to handle async trip fetching
                let group = DispatchGroup()
                var driverTrips: [String: [Trip]] = [:]
                
                // Fetch trips for each driver
                for driver in drivers {
                    group.enter()
                    
                    self.db.collection("trips")
                        .whereField("driverId", isEqualTo: driver.id)
                        .getDocuments { snapshot, error in
                            defer { group.leave() }
                            
                            if let error = error {
                                print("Error fetching trips for driver \(driver.id): \(error.localizedDescription)")
                                return
                            }
                            
                            let trips = snapshot?.documents.compactMap { document -> Trip? in
                                try? document.data(as: Trip.self)
                            } ?? []
                            
                            driverTrips[driver.id] = trips
                        }
                }
                
                // Wait for all trip fetches to complete
                group.notify(queue: .main) {
                    // Generate PDF content with all the data
                    let pdfContent = self.createDriverReportContent(drivers: drivers, driverTrips: driverTrips)
                    self.generatePDF(from: pdfContent)
                }
            }
    }
    
    private func generateVehicleReport() {
        db.collection("vehicles").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }
            
            // Generate PDF content
            let pdfContent = self.createVehicleReportContent(snapshot: snapshot)
            self.generatePDF(from: pdfContent)
        }
    }
    
    private func generateExpenseReport() {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        db.collection("trips")
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                // Generate PDF content
                let pdfContent = self.createExpenseReportContent(snapshot: snapshot)
                self.generatePDF(from: pdfContent)
            }
    }
    
    private func generatePDF(from content: String) {
        let pdfMetaData = [
            kCGPDFContextCreator: "Fleetly",
            kCGPDFContextAuthor: "Fleet Manager",
            kCGPDFContextTitle: selectedReportType.rawValue
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        do {
            let data = try renderer.pdfData { context in
                let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont
                ]
                let contentFont = UIFont.systemFont(ofSize: 12.0)
                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: contentFont
                ]
                
                // Split content into lines
                let lines = content.components(separatedBy: .newlines)
                
                var currentPage = 1
                var currentY: CGFloat = 50 // Start position for content
                let lineHeight: CGFloat = 20 // Height between lines
                let margin: CGFloat = 50 // Left and right margins
                let pageBottomMargin: CGFloat = 50 // Bottom margin
                
                // Draw title on first page
                let attributedTitle = NSAttributedString(string: selectedReportType.rawValue, attributes: titleAttributes)
                attributedTitle.draw(at: CGPoint(x: margin, y: currentY))
                currentY += 40 // Space after title
                
                // Process each line
                for line in lines {
                    // Check if we need a new page
                    if currentY + lineHeight > pageHeight - pageBottomMargin {
                        context.beginPage()
                        currentPage += 1
                        currentY = 50 // Reset Y position for new page
                        
                        // Add page number
                        let pageText = "Page \(currentPage)"
                        let pageAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 10.0)
                        ]
                        let attributedPage = NSAttributedString(string: pageText, attributes: pageAttributes)
                        let pageTextWidth = attributedPage.size().width
                        attributedPage.draw(at: CGPoint(x: pageWidth - margin - pageTextWidth, y: 30))
                    }
                    
                    // Draw the line
                    let attributedLine = NSAttributedString(string: line, attributes: contentAttributes)
                    attributedLine.draw(at: CGPoint(x: margin, y: currentY))
                    currentY += lineHeight
                }
            }
            
            DispatchQueue.main.async {
                self.generatedPDF = data
                self.showPDF = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to generate PDF: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Report Content Generators
    private func createTripReportContent(trips: [Trip]) -> String {
        var content = "Trip Report\n\n"
        content += "Date Range: \(formatDate(dateRange.lowerBound)) to \(formatDate(dateRange.upperBound))\n\n"
        
        // Summary
        content += "Summary:\n"
        content += "Total Trips: \(trips.count)\n"
        content += "Completed Trips: \(trips.filter { $0.status == .completed }.count)\n"
        content += "Active Trips: \(trips.filter { $0.status == .inProgress }.count)\n"
        content += "Cancelled Trips: \(trips.filter { $0.status == .cancelled }.count)\n\n"
        
        // Trip Statistics
        let totalDistance = trips.reduce(into: 0.0) { result, trip in
            result += trip.loadWeight ?? 0.0
        }
        let totalPassengers = trips.reduce(into: 0) { result, trip in
            result += trip.passengers ?? 0
        }
        let totalLoadWeight = trips.reduce(into: 0.0) { result, trip in
            result += trip.loadWeight ?? 0.0
        }
        
        content += "Trip Statistics:\n"
        content += "Total Distance: \(String(format: "%.2f", totalDistance)) km\n"
        content += "Total Passengers: \(totalPassengers)\n"
        content += "Total Load Weight: \(String(format: "%.2f", totalLoadWeight)) kg\n\n"
        
        // Detailed Trip List
        content += "Detailed Trip List:\n"
        for trip in trips {
            content += "\nTrip ID: \(trip.id)"
            content += "\nFrom: \(trip.startLocation)"
            content += "\nTo: \(trip.endLocation)"
            content += "\nDate: \(trip.date)"
            content += "\nTime: \(trip.time)"
            content += "\nStatus: \(trip.status.rawValue)"
            content += "\nVehicle Type: \(trip.vehicleType)"
            if let passengers = trip.passengers {
                content += "\nPassengers: \(passengers)"
            }
            if let loadWeight = trip.loadWeight {
                content += "\nLoad Weight: \(loadWeight) kg"
            }
            content += "\n-------------------"
        }
        
        return content
    }
    
    private func createMaintenanceReportContent(tasksWithCosts: [(MaintenanceTask, Inventory.MaintenanceCost?)]) -> String {
        var content = "Maintenance Report\n\n"
        content += "Date Range: \(formatDate(dateRange.lowerBound)) to \(formatDate(dateRange.upperBound))\n\n"
        
        if tasksWithCosts.isEmpty {
            return content + "No maintenance records found for the selected date range."
        }
        
        let maintenanceTasks = tasksWithCosts.map { $0.0 }
        
        // Task Status Summary
        content += "Task Status Summary:\n"
        content += "Total Maintenance Tasks: \(maintenanceTasks.count)\n"
        content += "Pending Tasks: \(maintenanceTasks.filter { $0.status == .pending }.count)\n"
        content += "In Progress Tasks: \(maintenanceTasks.filter { $0.status == .inProgress }.count)\n"
        content += "Completed Tasks: \(maintenanceTasks.filter { $0.status == .completed }.count)\n"
        content += "Cancelled Tasks: \(maintenanceTasks.filter { $0.status == .cancelled }.count)\n\n"
        
        // Priority Distribution
        let priorityGroups = Dictionary(grouping: maintenanceTasks) { $0.priority }
        content += "Priority Distribution:\n"
        for (priority, tasks) in priorityGroups {
            content += "\(priority): \(tasks.count) tasks\n"
        }
        content += "\n"
        
        // Cost Summary
        let completedTasksWithCosts = tasksWithCosts.filter { $0.0.status == .completed && $0.1 != nil }
        if !completedTasksWithCosts.isEmpty {
            let totalLaborCost = completedTasksWithCosts.reduce(0.0) { $0 + ($1.1?.laborCost ?? 0) }
            let totalPartsCost = completedTasksWithCosts.reduce(0.0) { $0 + ($1.1?.partsUsed.reduce(0.0) { $0 + ($1.unitPrice * Double($1.quantity)) } ?? 0) }
            let totalOtherCosts = completedTasksWithCosts.reduce(0.0) { $0 + ($1.1?.otherCosts.reduce(0.0) { $0 + $1.amount } ?? 0) }
            
            content += "Cost Summary:\n"
            content += "Total Labor Cost: $\(String(format: "%.2f", totalLaborCost))\n"
            content += "Total Parts Cost: $\(String(format: "%.2f", totalPartsCost))\n"
            content += "Total Other Costs: $\(String(format: "%.2f", totalOtherCosts))\n"
            content += "Total Maintenance Cost: $\(String(format: "%.2f", totalLaborCost + totalPartsCost + totalOtherCosts))\n\n"
        }
        
        // Detailed Maintenance List
        content += "Detailed Maintenance List:\n"
        for (task, cost) in tasksWithCosts {
            content += "\nTask ID: \(task.id)"
            content += "\nVehicle ID: \(task.vehicleId)"
            content += "\nIssue: \(task.issue)"
            content += "\nStatus: \(task.status.rawValue)"
            content += "\nPriority: \(task.priority)"
            content += "\nAssigned To: \(task.assignedToId)"
            content += "\nCompletion Date: \(task.completionDate)"
            content += "\nCreated At: \(task.createdAt)"
            
            if let cost = cost {
                content += "\nCost Details:"
                content += "\n  Labor Cost: $\(String(format: "%.2f", cost.laborCost))"
                content += "\n  Parts Used:"
                for part in cost.partsUsed {
                    content += "\n    - \(part.partName) (Qty: \(part.quantity), Price: $\(String(format: "%.2f", part.unitPrice)))"
                }
                content += "\n  Other Costs:"
                for otherCost in cost.otherCosts {
                    content += "\n    - \(otherCost.description): $\(String(format: "%.2f", otherCost.amount))"
                }
                content += "\n  Total Cost: $\(String(format: "%.2f", cost.totalCost))"
            }
            
            content += "\n-------------------"
        }
        
        return content
    }
    
    private func createDriverReportContent(drivers: [User], driverTrips: [String: [Trip]]) -> String {
        var content = "Driver Performance Report\n\n"
        
        if drivers.isEmpty {
            return content + "No drivers found."
        }
        
        // Overall Statistics
        content += "Overall Statistics:\n"
        content += "Total Drivers: \(drivers.count)\n"
        content += "Active Drivers: \(drivers.filter { $0.isAvailable == true }.count)\n"
        content += "Approved Drivers: \(drivers.filter { $0.isApproved == true }.count)\n\n"
        
        // Driver Performance Summary
        content += "Driver Performance Summary:\n"
        for driver in drivers {
            let trips = driverTrips[driver.id] ?? []
            let completedTrips = trips.filter { $0.status == .completed }
            let cancelledTrips = trips.filter { $0.status == .cancelled }
            let totalDistance = completedTrips.reduce(0.0) { $0 + ($1.loadWeight ?? 0) }
            let totalPassengers = completedTrips.reduce(0) { $0 + ($1.passengers ?? 0) }
            
            content += "\nDriver: \(driver.name)"
            content += "\nLicense Number: \(driver.drivingLicenseNumber ?? "Not provided")"
            content += "\nStatus: \(driver.isApproved == true ? "Approved" : "Pending Approval")"
            content += "\nAvailability: \(driver.isAvailable == true ? "Available" : "Not Available")"
            content += "\nTotal Trips: \(trips.count)"
            content += "\nCompleted Trips: \(completedTrips.count)"
            content += "\nCancelled Trips: \(cancelledTrips.count)"
            content += "\nCompletion Rate: \(trips.isEmpty ? "0" : String(format: "%.1f", Double(completedTrips.count) / Double(trips.count) * 100))%"
            content += "\nTotal Distance: \(String(format: "%.1f", totalDistance)) km"
            content += "\nTotal Passengers: \(totalPassengers)"
            
            if !completedTrips.isEmpty {
                let averageTripDuration = completedTrips.reduce(0.0) { total, trip in
                    if let endTime = trip.endTime {
                        return total + endTime.timeIntervalSince(trip.startTime)
                    }
                    return total
                } / Double(completedTrips.count)
                
                let hours = Int(averageTripDuration) / 3600
                let minutes = (Int(averageTripDuration) % 3600) / 60
                content += "\nAverage Trip Duration: \(hours)h \(minutes)m"
            }
            
            content += "\n-------------------"
        }
        
        // Detailed Trip Analysis
        content += "\n\nDetailed Trip Analysis:\n"
        for driver in drivers {
            let trips = driverTrips[driver.id] ?? []
            if !trips.isEmpty {
                content += "\nDriver: \(driver.name)"
                
                // Group trips by status
                let tripsByStatus = Dictionary(grouping: trips) { $0.status }
                for (status, statusTrips) in tripsByStatus {
                    content += "\n\(status.rawValue.capitalized) Trips:"
                    for trip in statusTrips {
                        content += "\n  - Date: \(trip.date)"
                        content += "\n    Time: \(trip.time)"
                        content += "\n    Route: \(trip.startLocation) to \(trip.endLocation)"
                        if let passengers = trip.passengers {
                            content += "\n    Passengers: \(passengers)"
                        }
                        if let loadWeight = trip.loadWeight {
                            content += "\n    Load Weight: \(loadWeight) kg"
                        }
                        content += "\n    Vehicle Type: \(trip.vehicleType)"
                    }
                }
                content += "\n-------------------"
            }
        }
        
        return content
    }
    
    private func createVehicleReportContent(snapshot: QuerySnapshot?) -> String {
        var content = "Vehicle Status Report\n\n"
        
        guard let documents = snapshot?.documents else {
            return content + "No vehicle records found."
        }
        
        let vehicles = documents.compactMap { document -> Vehicle? in
            try? document.data(as: Vehicle.self)
        }
        
        // Summary
        content += "Summary:\n"
        content += "Total Vehicles: \(vehicles.count)\n"
        content += "Active Vehicles: \(vehicles.filter { $0.status == .active }.count)\n"
        content += "In Maintenance: \(vehicles.filter { $0.status == .inMaintenance }.count)\n"
        content += "Deactivated: \(vehicles.filter { $0.status == .deactivated }.count)\n\n"
        
        // Vehicle Types Distribution
        let vehicleTypes = Dictionary(grouping: vehicles) { $0.vehicleType }
        content += "Vehicle Types Distribution:\n"
        for (type, vehicles) in vehicleTypes {
            content += "\(type.rawValue): \(vehicles.count)\n"
        }
        content += "\n"
        
        // Detailed Vehicle List
        content += "Detailed Vehicle List:\n"
        for vehicle in vehicles {
            content += "\nVehicle ID: \(vehicle.id)"
            content += "\nMake: \(vehicle.make)"
            content += "\nModel: \(vehicle.model)"
            content += "\nYear: \(vehicle.year)"
            content += "\nLicense Plate: \(vehicle.licensePlate)"
            content += "\nVIN: \(vehicle.vin)"
            content += "\nType: \(vehicle.vehicleType.rawValue)"
            content += "\nStatus: \(vehicle.status.rawValue)"
            if let passengerCapacity = vehicle.passengerCapacity {
                content += "\nPassenger Capacity: \(passengerCapacity)"
            }
            if let cargoCapacity = vehicle.cargoCapacity {
                content += "\nCargo Capacity: \(cargoCapacity) kg"
            }
            content += "\n-------------------"
        }
        
        return content
    }
    
    private func createExpenseReportContent(snapshot: QuerySnapshot?) -> String {
        var content = "Expense Report\n\n"
        content += "Date Range: \(formatDate(dateRange.lowerBound)) to \(formatDate(dateRange.upperBound))\n\n"
        
        guard let documents = snapshot?.documents else {
            return content + "No expense records found for the selected date range."
        }
        
        let trips = documents.compactMap { document -> Trip? in
            try? document.data(as: Trip.self)
        }
        
        // Summary
        content += "Summary:\n"
        content += "Total Trips: \(trips.count)\n"
        
        // Trip Statistics
        let totalDistance = trips.reduce(into: 0.0) { result, trip in
            result += trip.loadWeight ?? 0.0
        }
        let totalPassengers = trips.reduce(into: 0) { result, trip in
            result += trip.passengers ?? 0
        }
        let totalLoadWeight = trips.reduce(into: 0.0) { result, trip in
            result += trip.loadWeight ?? 0.0
        }
        
        content += "\nTrip Statistics:\n"
        content += "Total Distance: \(String(format: "%.2f", totalDistance)) km\n"
        content += "Total Passengers: \(totalPassengers)\n"
        content += "Total Load Weight: \(String(format: "%.2f", totalLoadWeight)) kg\n\n"
        
        // Detailed Trip List
        content += "Detailed Trip List:\n"
        for trip in trips {
            content += "\nTrip ID: \(trip.id)"
            content += "\nDate: \(trip.date)"
            content += "\nTime: \(trip.time)"
            content += "\nFrom: \(trip.startLocation)"
            content += "\nTo: \(trip.endLocation)"
            content += "\nVehicle: \(trip.vehicleId)"
            content += "\nStatus: \(trip.status.rawValue)"
            if let passengers = trip.passengers {
                content += "\nPassengers: \(passengers)"
            }
            if let loadWeight = trip.loadWeight {
                content += "\nLoad Weight: \(loadWeight) kg"
            }
            content += "\n-------------------"
        }
        
        return content
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - ReportsView
struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Report Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Type")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ReportType.allCases, id: \.self) { type in
                                    ReportTypeButton(
                                        type: type,
                                        isSelected: viewModel.selectedReportType == type,
                                        action: { viewModel.selectedReportType = type }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Date Range Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date Range")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 16) {
                            DateRangePicker(
                                startDate: Binding(
                                    get: { viewModel.dateRange.lowerBound },
                                    set: { viewModel.dateRange = $0...viewModel.dateRange.upperBound }
                                ),
                                endDate: Binding(
                                    get: { viewModel.dateRange.upperBound },
                                    set: { viewModel.dateRange = viewModel.dateRange.lowerBound...$0 }
                                )
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Generate Report Button
                    Button(action: {
                        viewModel.generateReport()
                    }) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Generate Report")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                    
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                            Text("Generating Report...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    if viewModel.generatedPDF != nil {
                        // Download Button
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Download Report")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPDF) {
                if let pdfData = viewModel.generatedPDF {
                    NavigationStack {
                        PDFKitView(data: pdfData)
                            .navigationTitle("Report Preview")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        viewModel.showPDF = false
                                    }
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = viewModel.generatedPDF {
                    ShareSheet(activityItems: [pdfData])
                }
            }
        }
    }
}

// MARK: - Report Type Button
struct ReportTypeButton: View {
    let type: ReportType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// MARK: - Date Range Picker
struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $startDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $endDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - PDFKit View
struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportsView()
}
