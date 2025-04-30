import SwiftUI

struct ScheduleView: View {
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

    @State private var workOrdersByDate: [String: [WorkOrder]] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let today = Date()
        let calendar = Calendar.current

        func dateStr(_ offset: Int) -> String {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            return formatter.string(from: date)
        }

        return [
            dateStr(0): [
                WorkOrder(id: 1001, vehicleNumber: "KA01AB4321", issue: "Brake Check", status: "To be Done", expectedDelivery: "6:00 PM", priority: "Medium"),
                WorkOrder(id: 1002, vehicleNumber: "KA05CD1234", issue: "Engine Overhaul", status: "In Progress", expectedDelivery: "8:00 PM", priority: "High")
            ],
            dateStr(-1): [
                WorkOrder(id: 999, vehicleNumber: "KA09EF5678", issue: "Oil Change", status: "Completed", expectedDelivery: nil, priority: "Low"),
                WorkOrder(id: 998, vehicleNumber: "KA04GH8765", issue: "Suspension Repair", status: "To be Done", expectedDelivery: "5:00 PM", priority: "Medium")
            ],
            dateStr(-2): [
                WorkOrder(id: 997, vehicleNumber: "KA03YZ9087", issue: "AC Gas Refill", status: "Completed", expectedDelivery: nil, priority: "Low")
            ],
            dateStr(1): [
                WorkOrder(id: 1003, vehicleNumber: "KA02GH8910", issue: "Battery Replacement", status: "To be Done", expectedDelivery: "7:00 PM", priority: "High"),
                WorkOrder(id: 1004, vehicleNumber: "KA03IJ1122", issue: "Wheel Alignment", status: "To be Done", expectedDelivery: "6:30 PM", priority: "Medium")
            ],
            dateStr(2): [
                WorkOrder(id: 1006, vehicleNumber: "KA06OP2211", issue: "Fuel Injector Cleaning", status: "In Progress", expectedDelivery: "10:00 AM", priority: "Low")
            ]
        ]
    }()

    var selectedWorkOrders: [WorkOrder] {
        let key = formatter.string(from: selectedDate)
        let orders = workOrdersByDate[key] ?? []
        return orders.sorted { priorityOrder($0.priority) < priorityOrder($1.priority) }
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
                                Button(action: { selectedDate = date }) {
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
                    if selectedWorkOrders.isEmpty {
                        Text("No maintenance tasks on this date")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(hex: "444444"))
                            .padding()
                    } else {
                        ForEach(selectedWorkOrders, id: \.id) { order in
                            if let index = indexOfWorkOrder(order) {
                                let binding = bindingForWorkOrder(at: index)
                                let isCompleted = order.status.lowercased() == "completed"
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(formatter.string(from: selectedDate))
                                            .font(.system(.caption, design: .rounded))
                                        Spacer()
                                        Menu {
                                            Button("To be Done", action: { binding?.wrappedValue.status = "To be Done" })
                                            Button("In Progress", action: { binding?.wrappedValue.status = "In Progress" })
                                            Button("Completed", action: { binding?.wrappedValue.status = "Completed" })
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
                                            Button("High", action: { binding?.wrappedValue.priority = "High" })
                                            Button("Medium", action: { binding?.wrappedValue.priority = "Medium" })
                                            Button("Low", action: { binding?.wrappedValue.priority = "Low" })
                                        } label: {
                                            HStack(spacing: 2) {
                                                Text(order.priority)
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
                }
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "F3F3F3").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func indexOfWorkOrder(_ order: WorkOrder) -> Int? {
        let key = formatter.string(from: selectedDate)
        return workOrdersByDate[key]?.firstIndex { $0.id == order.id }
    }

    private func bindingForWorkOrder(at index: Int) -> Binding<WorkOrder>? {
        let key = formatter.string(from: selectedDate)
        guard var orders = workOrdersByDate[key], index < orders.count else { return nil }
        return Binding(
            get: { workOrdersByDate[key]?[index] ?? orders[index] },
            set: { newValue in workOrdersByDate[key]?[index] = newValue }
        )
    }

    private func priorityOrder(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "high": return 0
        case "medium": return 1
        case "low": return 2
        default: return 3
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

    private func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .yellow
        case "low": return .green
        default: return .gray
        }
    }

    private func priorityBackgroundColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return Color.red.opacity(0.2)
        case "medium": return Color.yellow.opacity(0.2)
        case "low": return Color.green.opacity(0.2)
        default: return Color.gray.opacity(0.2)
        }
    }

    struct WorkOrder: Identifiable {
        let id: Int
        let vehicleNumber: String
        let issue: String
        var status: String
        let expectedDelivery: String?
        var priority: String
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}
