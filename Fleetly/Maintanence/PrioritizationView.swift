import SwiftUI

struct PrioritizationView: View {
    @Binding var workOrders: [WorkOrder]
    @Environment(\.dismiss) var dismiss
    @State private var selectedOrder: WorkOrder?
    @State private var selectedPriority: String = "Low"
    let priorityOptions = ["High", "Medium", "Low"]

    var body: some View {
        NavigationView {
            ZStack {
                // Blurred Background
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    Text("Prioritize Work Orders")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    // List of Work Orders
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(workOrders, id: \.id) { order in
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Work Order #\(order.id)")
                                                .font(.system(.headline, design: .rounded).weight(.medium))
                                                .foregroundColor(.primary)
                                            Text("Vehicle: \(order.vehicleNumber)")
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(priorityText(order.priority))
                                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                                            .foregroundColor(priorityColor(order.priority))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(priorityColor(order.priority).opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedOrder = order
                                            selectedPriority = priorityText(order.priority)
                                        }
                                    }
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                }
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.top, 40)

                // Priority Selection Sheet for Selected Order
                if let order = selectedOrder {
                    VStack(spacing: 16) {
                        Text("Set Priority for Work Order #\(order.id)")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)

                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(priorityOptions, id: \.self) { priority in
                                Text(priority).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)

                        HStack(spacing: 20) {
                            Button("Cancel") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedOrder = nil
                                }
                            }
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())

                            Button("Apply") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if let index = workOrders.firstIndex(where: { $0.id == order.id }) {
                                        workOrders[index].priority = priorityValue(selectedPriority)
                                    }
                                    selectedOrder = nil
                                }
                            }
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(
                        Color.white
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                    .offset(y: selectedOrder != nil ? 0 : UIScreen.main.bounds.height)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedOrder)
                }
            }
            .navigationBarItems(trailing: Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.blue)
            })
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .green
        }
    }

    private func priorityValue(_ priority: String) -> Int {
        switch priority {
        case "High": return 2
        case "Medium": return 1
        case "Low": return 0
        default: return 0
        }
    }
}
