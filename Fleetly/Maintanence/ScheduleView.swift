import SwiftUI
import Firebase
import FirebaseFirestore

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonthOffset = 0
    let today = Date()
    let calendar = Calendar.current
    private let formatter = DateFormatter()
    private let displayFormatter = DateFormatter()

    init() {
        formatter.dateFormat = "dd-MM-yyyy"
        displayFormatter.dateFormat = "MMMM yyyy"
    }

    var startOfMonth: Date {
        let start = calendar.date(byAdding: .month, value: currentMonthOffset, to: today)!
        return calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
    }

    var daysInMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        return range.count
    }

    var firstDayOfMonth: Int {
        calendar.component(.weekday, from: startOfMonth) - 1 // 0 (Sunday) to 6 (Saturday)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Schedule")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Calendar Section
                VStack(spacing: 10) {
                    HStack {
                        Text(displayFormatter.string(from: startOfMonth))
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundColor(.blue)
                        Spacer()
                        HStack(spacing: 10) {
                            Button(action: { withAnimation { currentMonthOffset -= 1 } }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.blue)
                            }
                            Button(action: { withAnimation { currentMonthOffset += 1 } }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    HStack(spacing: 0) {
                        ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                            Text(day)
                                .frame(maxWidth: .infinity)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                        ForEach(0..<(firstDayOfMonth + daysInMonth), id: \.self) { index in
                            if index < firstDayOfMonth {
                                Color.clear
                                    .frame(width: 30, height: 30)
                            } else {
                                let day = index - firstDayOfMonth + 1
                                let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
                                Button(action: {
                                    selectedDate = date
                                    viewModel.fetchWorkOrders(for: date)
                                }) {
                                    Text("\(day)")
                                        .frame(width: 30, height: 30)
                                        .background(
                                            calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue.opacity(0.2) : Color.clear
                                        )
                                        .foregroundColor(
                                            calendar.isDate(date, inSameDayAs: today) ? .blue : .black
                                        )
                                        .overlay(
                                            calendar.isDate(date, inSameDayAs: today) ?
                                            Circle().stroke(Color.blue, lineWidth: 1) : nil
                                        )
                                        .cornerRadius(15)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)

                // Work Order Details
                VStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.selectedWorkOrders.isEmpty {
                        Text("No maintenance tasks on this date")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(hex: "444444"))
                            .padding()
                    } else {
                        ForEach(viewModel.selectedWorkOrders.indices, id: \.self) { index in
                            let order = viewModel.selectedWorkOrders[index]
                            let isCompleted = order.status.lowercased() == "completed"
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(formatter.string(from: selectedDate))
                                        .font(.system(.caption, design: .rounded))
                                    Spacer()
                                    Menu {
                                        Button("To be Done", action: { viewModel.updateTaskStatus(taskId: order.id, newStatus: "To be Done") })
                                        Button("In Progress", action: { viewModel.updateTaskStatus(taskId: order.id, newStatus: "In Progress") })
                                        Button("Completed", action: { viewModel.updateTaskStatus(taskId: order.id, newStatus: "Completed") })
                                    } label: {
                                        HStack(spacing: 2) {
                                            Text(order.status)
                                                .font(.system(size: 14, design: .rounded).weight(.medium))
                                                .foregroundColor(statusColor(for: order.status))
                                            if isCompleted {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(statusColor(for: order.status))
                                            }
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(statusBackgroundColor(for: order.status))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                        )
                                    }
                                    Menu {
                                        Button("High", action: { viewModel.updateTaskPriority(taskId: order.id, newPriority: "High") })
                                        Button("Medium", action: { viewModel.updateTaskPriority(taskId: order.id, newPriority: "Medium") })
                                        Button("Low", action: { viewModel.updateTaskPriority(taskId: order.id, newPriority: "Low") })
                                    } label: {
                                        HStack(spacing: 2) {
                                            Text(priorityText(for: order.priority))
                                                .font(.system(size: 14, design: .rounded).weight(.medium))
                                                .foregroundColor(priorityColor(for: order.priority))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(priorityBackgroundColor(for: order.priority))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                        )
                                    }
                                }
                                Text(order.vehicleNumber)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .overlay(
                                        isCompleted ?
                                        GeometryReader { geometry in
                                            Path { path in
                                                let width = geometry.size.width
                                                let height = geometry.size.height
                                                path.move(to: CGPoint(x: 0, y: height / 2))
                                                path.addLine(to: CGPoint(x: width, y: height / 2))
                                            }
                                            .stroke(Color.gray, lineWidth: 1)
                                        } : nil
                                    )
                                Text(order.issue)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.gray)
                                    .overlay(
                                        isCompleted ?
                                        GeometryReader { geometry in
                                            Path { path in
                                                let width = geometry.size.width
                                                let height = geometry.size.height
                                                path.move(to: CGPoint(x: 0, y: height / 2))
                                                path.addLine(to: CGPoint(x: width, y: height / 2))
                                            }
                                            .stroke(Color.gray, lineWidth: 1)
                                        } : nil
                                    )
                                if let delivery = order.expectedDelivery {
                                    Text("Expected Completion: \(delivery)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .opacity(isCompleted ? 0.7 : 1.0)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "F3F3F3").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchWorkOrders(for: selectedDate)
            }
        }
    }

    private func priorityText(for priority: Int) -> String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Low"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "in progress": return .orange
        case "to be done", "scheduled": return .blue
        default: return .gray
        }
    }

    private func statusBackgroundColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed": return Color.green.opacity(0.2)
        case "in progress": return Color.orange.opacity(0.2)
        case "to be done", "scheduled": return Color.blue.opacity(0.2)
        default: return Color.gray.opacity(0.2)
        }
    }

    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 0: return .green // Low
        case 1: return .yellow // Medium
        case 2: return .red // High
        default: return .gray
        }
    }

    private func priorityBackgroundColor(for priority: Int) -> Color {
        switch priority {
        case 0: return Color.green.opacity(0.2) // Low
        case 1: return Color.yellow.opacity(0.2) // Medium
        case 2: return Color.red.opacity(0.2) // High
        default: return Color.gray.opacity(0.2)
        }
    }
}

class ScheduleViewModel: ObservableObject {
    @Published var selectedWorkOrders: [WorkOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    deinit {
        listener?.remove()
    }
    
    func fetchWorkOrders(for date: Date) {
        isLoading = true
        listener?.remove() // Remove previous listener to avoid duplicates
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)
        
        listener = db.collection("maintenance_tasks")
            .whereField("assignedToId", isEqualTo: "maintenance_user_id") // Replace with actual user ID
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
                            // Filter tasks for the selected date
                            if let taskDate = workOrder.completionDateAsDate,
                               Calendar.current.isDate(taskDate, inSameDayAs: date) {
                                orders.append(workOrder)
                            }
                        } catch {
                            self.errorMessage = "Error decoding task: \(error.localizedDescription)"
                        }
                    }
                    self.selectedWorkOrders = orders.sorted { $0.priority > $1.priority }
                }
            }
    }
    
    func updateTaskStatus(taskId: String, newStatus: String) {
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
            }
        }
    }
    
    func updateTaskPriority(taskId: String, newPriority: String) {
        db.collection("maintenance_tasks").document(taskId).updateData(["priority": newPriority]) { error in
            if let error = error {
                self.errorMessage = "Error updating priority: \(error.localizedDescription)"
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

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
