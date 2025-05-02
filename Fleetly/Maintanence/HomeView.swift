import SwiftUI
import UIKit
import Firebase
import FirebaseFirestore

// ViewModel to fetch tasks and inventory from Firestore
class HomeViewModel: ObservableObject {
    @Published var workOrders: [WorkOrder] = []
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var isInventoryLoading = false
    @Published var errorMessage: String?
    @Published var inventoryErrorMessage: String?
    
    private let db = Firestore.firestore()
    private var taskListener: ListenerRegistration?
    private var inventoryListener: ListenerRegistration?
    
    init() {
        fetchWorkOrders()
        fetchInventory()
    }
    
    deinit {
        taskListener?.remove()
        inventoryListener?.remove()
    }
    
    func fetchWorkOrders() {
        isLoading = true
        taskListener = db.collection("maintenance_tasks")
            .whereField("assignedToId", isEqualTo: "maintenance_user_id") // Replace with actual user ID
            .whereField("status", in: ["pending", "in_progress"])
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching tasks: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No tasks found"
                    return
                }
                
                Task {
                    var orders: [WorkOrder] = []
                    for document in documents {
                        do {
                            let task = try document.data(as: MaintenanceTask.self)
                            let vehicleNumber = await self.fetchVehicleNumber(for: task.vehicleId)
                            let workOrder = self.mapToWorkOrder(task: task, vehicleNumber: vehicleNumber)
                            orders.append(workOrder)
                        } catch {
                            self.errorMessage = "Error decoding task: \(error.localizedDescription)"
                        }
                    }
                    self.workOrders = orders.sorted { $0.priority > $1.priority }
                }
            }
    }
    
    func fetchInventory() {
        isInventoryLoading = true
        inventoryListener = db.collection("inventory")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isInventoryLoading = false
                
                if let error = error {
                    self.inventoryErrorMessage = "Error fetching inventory: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.inventoryErrorMessage = "No inventory items found"
                    return
                }
                
                self.inventoryItems = documents.compactMap { document in
                    guard let name = document.data()["name"] as? String,
                          let units = document.data()["units"] as? Int else {
                        return nil
                    }
                    return InventoryItem(id: document.documentID, name: name, units: units)
                }
            }
    }
    
    func updateTaskStatus(taskId: String, newStatus: String, completion: @escaping (Bool) -> Void) {
        let status: MaintenanceTask.TaskStatus
        switch newStatus.lowercased() {
        case "in progress":
            status = .inProgress
        case "completed":
            status = .completed
        case "to be done":
            status = .pending
        default:
            status = .pending
        }
        
        db.collection("maintenance_tasks").document(taskId).updateData(["status": status.rawValue]) { error in
            if let error = error {
                self.errorMessage = "Error updating status: \(error.localizedDescription)"
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func fetchVehicleNumber(for vehicleId: String) async -> String {
        do {
            let document = try await db.collection("vehicles").document(vehicleId).getDocument()
            if let data = document.data(),
               let licensePlate = data["licensePlate"] as? String {
                return licensePlate
            }
        } catch {
            self.errorMessage = "Error fetching vehicle: \(error.localizedDescription)"
        }
        return "Unknown Vehicle"
    }
    
    private func mapToWorkOrder(task: MaintenanceTask, vehicleNumber: String) -> WorkOrder {
        let priorityValue: Int
        switch task.priority.lowercased() {
        case "high": priorityValue = 2
        case "medium": priorityValue = 1
        case "low": priorityValue = 0
        default: priorityValue = 0
        }
        
        return WorkOrder(
            id: task.id,
            vehicleNumber: vehicleNumber,
            issue: task.issue,
            status: task.status.rawValue.capitalized,
            expectedDelivery: task.completionDate,
            priority: priorityValue,
            issues: [task.issue],
            parts: [],
            laborCost: nil
        )
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var currentWorkOrderIndex: Int = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 30) {
                    // Header
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Welcome \(getUserName())!")
                                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                    .foregroundColor(.primary)
                                Text("Here's your schedule for today!")
                                    .font(.system(.title3, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Assigned Work
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Assigned Work")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(.title3, design: .rounded).weight(.medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                        } else if currentWorkOrderIndex < viewModel.workOrders.count {
                            WorkOrderCard(
                                workOrder: $viewModel.workOrders[currentWorkOrderIndex],
                                onStatusChange: { newStatus, workOrderId in
                                    viewModel.updateTaskStatus(taskId: workOrderId, newStatus: newStatus) { success in
                                        if success {
                                            if newStatus == "Completed" {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                    if currentWorkOrderIndex < viewModel.workOrders.count - 1 {
                                                        currentWorkOrderIndex += 1
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            )
                        } else {
                            Text("No Work Orders Left")
                                .font(.system(.title3, design: .rounded).weight(.medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                .padding(.horizontal, 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    
                    // Inventory
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Inventory")
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundColor(.darkGray)
                            Spacer()
                            NavigationLink("View All", destination: InventoryManagementView()) // Removed 'items' parameter
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(.customBlue)
                        }
                        .padding(.horizontal, 20)
                        
                        if viewModel.isInventoryLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if let errorMessage = viewModel.inventoryErrorMessage {
                            Text(errorMessage)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                        } else {
                            HStack(spacing: 16) {
                                ForEach(viewModel.inventoryItems.prefix(4)) { item in
                                    InventoryIcon(item: item)
                                        .background(Color.backgroundGray)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                            .frame(width: 353, height: 120)
                            .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Alerts
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Alerts")
                            .font(.system(.title2, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                        
                        AlertItem(text: "Vehicle 23 needs maintenance")
                        AlertItem(text: "Vehicle 2 is due for service in 3 days")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private func getUserName() -> String {
        return "manash"
    }
}

struct WorkOrderCard: View {
    @Binding var workOrder: WorkOrder
    var onStatusChange: (String, String) -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let sliderWidth: CGFloat = UIScreen.main.bounds.width - 60
    private let swipeThreshold: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: ID and Vehicle Number
            HStack {
                Text("Work Order #\(workOrder.id)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.darkGray)
                Spacer()
                Text(workOrder.vehicleNumber)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.gray)
            }
            
            // Body: Issue, Delivery, Issues
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(.customBlue)
                        .imageScale(.small)
                    Text(workOrder.issue)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.darkGray)
                }
                if let delivery = workOrder.expectedDelivery {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .imageScale(.small)
                        Text("Due: \(delivery)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                if !workOrder.issues.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .imageScale(.small)
                        Text("Issues: \(workOrder.issues.joined(separator: ", "))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Status and Priority
            HStack(spacing: 10) {
                // Status Badge
                HStack(spacing: 4) {
                    Image(systemName: statusIcon(workOrder.status))
                        .foregroundColor(statusColor(workOrder.status))
                        .imageScale(.small)
                    Text(workOrder.status)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(statusColor(workOrder.status))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(workOrder.status).opacity(0.15))
                .cornerRadius(6)
                
                // Priority Badge
                HStack(spacing: 4) {
                    Image(systemName: priorityIcon(workOrder.priority))
                        .foregroundColor(priorityColor(workOrder.priority))
                        .imageScale(.small)
                    Text(priorityText(workOrder.priority))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(priorityColor(workOrder.priority))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor(workOrder.priority).opacity(0.15))
                .cornerRadius(6)
            }
            
            // Action
            if workOrder.status.lowercased() == "to be done" {
                VStack(spacing: 8) {
                    Text("Slide to Start")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.lightGray)
                            .frame(height: 48)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(dragOffset, sliderWidth)), height: 48)
                        
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                            Image(systemName: "wrench.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(dragOffset >= swipeThreshold ? .todayGreen : .darkGray)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDragging = true
                                    dragOffset = max(0, min(value.translation.width, sliderWidth))
                                    if dragOffset >= swipeThreshold {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                                .onEnded { _ in
                                    if dragOffset >= swipeThreshold {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            workOrder.status = "In Progress"
                                            onStatusChange("In Progress", workOrder.id)
                                            dragOffset = 0
                                            isDragging = false
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            dragOffset = 0
                                            isDragging = false
                                        }
                                    }
                                }
                        )
                    }
                    .frame(height: 48)
                }
            } else if workOrder.status.lowercased() == "in progress" {
                Button(action: {
                    withAnimation {
                        workOrder.status = "Completed"
                        onStatusChange("Completed", workOrder.id)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.medium)
                        Text("Mark as Completed")
                            .font(.system(.headline, design: .rounded).weight(.medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else if workOrder.status.lowercased() == "completed" {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.todayGreen)
                        .imageScale(.medium)
                    Text("Work Order Completed")
                        .font(.system(.headline, design: .rounded).weight(.medium))
                        .foregroundColor(.todayGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.todayGreen.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .id(workOrder.id)
        .onAppear {
            dragOffset = 0
            isDragging = false
        }
    }
    
    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Low"
        }
    }
    
    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 0: return .todayGreen
        case 1: return .orange
        case 2: return .red
        default: return .todayGreen
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .todayGreen
        case "in progress": return .orange
        case "to be done": return .red
        default: return .gray
        }
    }
    
    private func statusIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "completed": return "checkmark.circle.fill"
        case "in progress": return "gearshape.fill"
        case "to be done": return "hourglass"
        default: return "questionmark.circle"
        }
    }
    
    private func priorityIcon(_ priority: Int) -> String {
        switch priority {
        case 0: return "arrow.down.circle"
        case 1: return "arrow.right.circle"
        case 2: return "arrow.up.circle"
        default: return "arrow.down.circle"
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
