import SwiftUI
import PDFKit
import Firebase
import FirebaseFirestore

class ReportsViewModel: ObservableObject {
    @Published var tripStats = TripStats()
    @Published var maintenanceStats = MaintenanceStats()
    @Published var driverStats = DriverStats()
    @Published var vehicleStats = VehicleStats()
    @Published var financialStats = FinancialStats()
    
    private let db = Firestore.firestore()
    
    // MARK: - Data Models
    struct TripStats {
        var totalTrips: Int = 0
        var totalDistance: Double = 0
        var avgDuration: Int = 0
    }
    
    struct MaintenanceStats {
        var totalTasks: Int = 0
        var completedTasks: Int = 0
        var totalCost: Double = 0
    }
    
    struct DriverStats {
        var activeDrivers: Int = 0
        var totalHours: Int = 0
        var avgRating: Double = 0
    }
    
    struct VehicleStats {
        var totalVehicles: Int = 0
        var activeVehicles: Int = 0
        var utilizationRate: Double = 0
    }
    
    struct FinancialStats {
        var totalRevenue: Double = 0
        var totalExpenses: Double = 0
        var netProfit: Double = 0
    }
    
    // MARK: - Data Fetching
    func fetchReportData(for type: ReportsView.ReportType, dateRange: ClosedRange<Date>) {
        switch type {
        case .trips:
            fetchTripStats(dateRange: dateRange)
        case .maintenance:
            fetchMaintenanceStats(dateRange: dateRange)
        case .driver:
            fetchDriverStats(dateRange: dateRange)
        case .vehicle:
            fetchVehicleStats(dateRange: dateRange)
        case .financial:
            fetchFinancialStats(dateRange: dateRange)
        }
    }
    
    private func fetchTripStats(dateRange: ClosedRange<Date>) {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        db.collection("trips")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                var totalDistance: Double = 0
                var totalDuration: Int = 0
                
                for doc in documents {
                    if let distance = doc.data()["distance"] as? Double {
                        totalDistance += distance
                    }
                    if let duration = doc.data()["duration"] as? Int {
                        totalDuration += duration
                    }
                }
                
                DispatchQueue.main.async {
                    self.tripStats = TripStats(
                        totalTrips: documents.count,
                        totalDistance: totalDistance,
                        avgDuration: documents.isEmpty ? 0 : totalDuration / documents.count
                    )
                }
            }
    }
    
    private func fetchMaintenanceStats(dateRange: ClosedRange<Date>) {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        db.collection("maintenance")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                var completedTasks = 0
                var totalCost: Double = 0
                
                for doc in documents {
                    if let status = doc.data()["status"] as? String,
                       status == "completed" {
                        completedTasks += 1
                    }
                    if let cost = doc.data()["cost"] as? Double {
                        totalCost += cost
                    }
                }
                
                DispatchQueue.main.async {
                    self.maintenanceStats = MaintenanceStats(
                        totalTasks: documents.count,
                        completedTasks: completedTasks,
                        totalCost: totalCost
                    )
                }
            }
    }
    
    private func fetchDriverStats(dateRange: ClosedRange<Date>) {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        // Fetch active drivers
        db.collection("users")
            .whereField("role", isEqualTo: "driver")
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                let activeDrivers = snapshot?.documents.count ?? 0
                
                // Fetch driver hours and ratings
                self.db.collection("trips")
                    .whereField("date", isGreaterThanOrEqualTo: startDate)
                    .whereField("date", isLessThanOrEqualTo: endDate)
                    .getDocuments { snapshot, error in
                        guard let documents = snapshot?.documents else { return }
                        
                        var totalHours = 0
                        var totalRating: Double = 0
                        var ratedTrips = 0
                        
                        for doc in documents {
                            if let duration = doc.data()["duration"] as? Int {
                                totalHours += duration / 60 // Convert minutes to hours
                            }
                            if let rating = doc.data()["rating"] as? Double {
                                totalRating += rating
                                ratedTrips += 1
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.driverStats = DriverStats(
                                activeDrivers: activeDrivers,
                                totalHours: totalHours,
                                avgRating: ratedTrips > 0 ? totalRating / Double(ratedTrips) : 0
                            )
                        }
                    }
            }
    }
    
    private func fetchVehicleStats(dateRange: ClosedRange<Date>) {
        // Fetch total vehicles
        db.collection("vehicles").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            let totalVehicles = snapshot?.documents.count ?? 0
            
            // Fetch active vehicles
            self.db.collection("vehicles")
                .whereField("status", isEqualTo: "active")
                .getDocuments { snapshot, error in
                    let activeVehicles = snapshot?.documents.count ?? 0
                    
                    // Calculate utilization rate
                    let utilizationRate = totalVehicles > 0 ? (Double(activeVehicles) / Double(totalVehicles)) * 100 : 0
                    
                    DispatchQueue.main.async {
                        self.vehicleStats = VehicleStats(
                            totalVehicles: totalVehicles,
                            activeVehicles: activeVehicles,
                            utilizationRate: utilizationRate
                        )
                    }
                }
        }
    }
    
    private func fetchFinancialStats(dateRange: ClosedRange<Date>) {
        let startDate = dateRange.lowerBound
        let endDate = dateRange.upperBound
        
        // Fetch revenue from trips
        db.collection("trips")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                var totalRevenue: Double = 0
                
                for doc in snapshot?.documents ?? [] {
                    if let revenue = doc.data()["revenue"] as? Double {
                        totalRevenue += revenue
                    }
                }
                
                // Fetch expenses from maintenance
                self.db.collection("maintenance")
                    .whereField("date", isGreaterThanOrEqualTo: startDate)
                    .whereField("date", isLessThanOrEqualTo: endDate)
                    .getDocuments { snapshot, error in
                        var totalExpenses: Double = 0
                        
                        for doc in snapshot?.documents ?? [] {
                            if let cost = doc.data()["cost"] as? Double {
                                totalExpenses += cost
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.financialStats = FinancialStats(
                                totalRevenue: totalRevenue,
                                totalExpenses: totalExpenses,
                                netProfit: totalRevenue - totalExpenses
                            )
                        }
                    }
            }
    }
    
    // MARK: - PDF Generation
    func generatePDF(type: ReportsView.ReportType, dateRange: ClosedRange<Date>) async throws -> URL {
        let pdfMetaData = [
            kCGPDFContextCreator: "Fleetly",
            kCGPDFContextAuthor: "Fleet Manager",
            kCGPDFContextTitle: "\(type.rawValue) Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let fileName = "\(type.rawValue)_\(dateFormatter.string(from: dateRange.lowerBound))_\(dateFormatter.string(from: dateRange.upperBound)).pdf"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()
            
            // Add header
            let titleFont = UIFont.boldSystemFont(ofSize: 24.0)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            let titleString = type.rawValue
            titleString.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Add date range
            let dateFont = UIFont.systemFont(ofSize: 12.0)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont
            ]
            let dateString = "Period: \(dateFormatter.string(from: dateRange.lowerBound)) - \(dateFormatter.string(from: dateRange.upperBound))"
            dateString.draw(at: CGPoint(x: 50, y: 80), withAttributes: dateAttributes)
            
            // Add report content based on type
            var yPosition: CGFloat = 120
            let contentFont = UIFont.systemFont(ofSize: 14.0)
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont
            ]
            
            switch type {
            case .trips:
                let content = [
                    "Total Trips: \(tripStats.totalTrips)",
                    "Total Distance: \(String(format: "%.2f", tripStats.totalDistance)) km",
                    "Average Duration: \(tripStats.avgDuration) minutes"
                ]
                for line in content {
                    line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    yPosition += 25
                }
                
            case .maintenance:
                let content = [
                    "Total Tasks: \(maintenanceStats.totalTasks)",
                    "Completed Tasks: \(maintenanceStats.completedTasks)",
                    "Total Cost: $\(String(format: "%.2f", maintenanceStats.totalCost))"
                ]
                for line in content {
                    line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    yPosition += 25
                }
                
            case .driver:
                let content = [
                    "Active Drivers: \(driverStats.activeDrivers)",
                    "Total Hours: \(driverStats.totalHours)",
                    "Average Rating: \(String(format: "%.1f", driverStats.avgRating))"
                ]
                for line in content {
                    line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    yPosition += 25
                }
                
            case .vehicle:
                let content = [
                    "Total Vehicles: \(vehicleStats.totalVehicles)",
                    "Active Vehicles: \(vehicleStats.activeVehicles)",
                    "Utilization Rate: \(String(format: "%.1f", vehicleStats.utilizationRate))%"
                ]
                for line in content {
                    line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    yPosition += 25
                }
                
            case .financial:
                let content = [
                    "Total Revenue: $\(String(format: "%.2f", financialStats.totalRevenue))",
                    "Total Expenses: $\(String(format: "%.2f", financialStats.totalExpenses))",
                    "Net Profit: $\(String(format: "%.2f", financialStats.netProfit))"
                ]
                for line in content {
                    line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                    yPosition += 25
                }
            }
            
            // Add footer
            let footerFont = UIFont.systemFont(ofSize: 10.0)
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: footerFont
            ]
            let footerString = "Generated on \(dateFormatter.string(from: Date()))"
            footerString.draw(at: CGPoint(x: 50, y: pageHeight - 50), withAttributes: footerAttributes)
        }
        
        return fileURL
    }
} 