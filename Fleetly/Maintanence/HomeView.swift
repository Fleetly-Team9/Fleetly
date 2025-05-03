import SwiftUI
import UIKit

struct HomeView: View {
    @State private var workOrders: [WorkOrder] = [
        WorkOrder(id: "23", vehicleNumber: "KA01AB4321", issue: "Brake Pad Replacement", status: "To be Done", expectedDelivery: "6:00 PM", priority: 2, issues: ["Worn brake pads"]),
        WorkOrder(id: "24", vehicleNumber: "KA02CD9876", issue: "Oil Change", status: "To be Done", expectedDelivery: "7:00 PM", priority: 1, issues: ["Low oil"]),
        WorkOrder(id: "25", vehicleNumber: "KA03EF5432", issue: "Tire Rotation", status: "To be Done", expectedDelivery: "8:00 PM", priority: 0, issues: ["Uneven wear"])
    ]
    @State private var showCardAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome, \(getUserName())!")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                            Text("Your tasks for today")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 44, height: 44)
                                        .shadow(radius: 4)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Overview Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        HStack(spacing: 16) {
                            OverviewStat(icon: "car.fill", title: "Total Vehicles", value: "19", color: .blue)
                            OverviewStat(icon: "wrench.and.screwdriver.fill", title: "Pending Tasks", value: "\(workOrders.count)", color: .orange)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Assigned Work Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Assigned Work")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        if workOrders.isEmpty {
                            Text("No Tasks Assigned")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.background)
                                        .overlay(.ultraThinMaterial)
                                        .shadow(radius: 2)
                                )
                                .padding(.horizontal, 16)
                        } else {
                            ForEach($workOrders, id: \.id) { $workOrder in
                                WorkOrderCard(
                                    workOrder: $workOrder,
                                    onStatusChange: { newStatus in
                                        print("Status changed to: \(newStatus) for Work Order #\(workOrder.id)")
                                        workOrder.status = newStatus
                                    }
                                )
                                .padding(.horizontal, 16)
                                .opacity(showCardAnimation ? 1 : 0)
                                .offset(y: showCardAnimation ? 0 : 20)
                                .animation(.easeOut(duration: 0.5).delay(Double(workOrders.firstIndex(where: { $0.id == workOrder.id }) ?? 0) * 0.1), value: showCardAnimation)
                            }
                        }
                    }

                    // Alerts Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Alerts")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        AlertItem(text: "Vehicle 23 needs maintenance")
                        AlertItem(text: "Vehicle 2 is due for service in 3 days")
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation {
                    showCardAnimation = true
                }
            }
        }
    }

    private func getUserName() -> String {
        return "Manash"
    }
}

struct OverviewStat: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.system(size: 28, weight: .medium))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.8))
                        .shadow(radius: 2)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: (UIScreen.main.bounds.width - 48) / 2, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .overlay(
                    LinearGradient(
                        colors: [color.opacity(0.05), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4, y: 2)
        )
    }
}

struct WorkOrderCard: View {
    @Binding var workOrder: WorkOrder
    var onStatusChange: (String) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var showAnimation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Work Order #\(workOrder.id)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(workOrder.vehicleNumber)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .background(Color.secondary.opacity(0.2))

            // Body
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.blue)
                        .imageScale(.medium)
                    Text(workOrder.issue)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                }
                if let delivery = workOrder.expectedDelivery {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                        Text("Due: \(delivery)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                let components = !workOrder.issues.isEmpty ? workOrder.issues : workOrder.parts
                if !components.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .imageScale(.medium)
                        Text("Issues: \(components.joined(separator: ", "))")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
            }

            // Status and Priority
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: statusIcon(workOrder.status))
                        .foregroundStyle(statusColor(workOrder.status))
                        .imageScale(.small)
                    Text(workOrder.status)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(statusColor(workOrder.status))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(workOrder.status).opacity(0.2))
                .clipShape(Capsule())

                HStack(spacing: 6) {
                    Image(systemName: priorityIcon(workOrder.priority))
                        .foregroundStyle(priorityColor(workOrder.priority))
                        .imageScale(.small)
                    Text(priorityText(workOrder.priority))
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(priorityColor(workOrder.priority))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(priorityColor(workOrder.priority).opacity(0.2))
                .clipShape(Capsule())
            }

            // Action
            if workOrder.status == "To be Done" {
                VStack(spacing: 10) {
                    Text("Slide to Start")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.blue)

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 50)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.3))
                            .frame(width: dragOffset, height: 50)

                        // Slider Knob
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 42, height: 42)
                                .shadow(radius: 2)
                            Image(systemName: "wrench.fill")
                                .foregroundStyle(showAnimation ? .blue : .gray)
                                .imageScale(.large)
                                .scaleEffect(showAnimation ? 1.1 : 1.0)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let maxWidth = UIScreen.main.bounds.width - 80
                                    dragOffset = min(max(value.translation.width, 0), maxWidth)
                                    showAnimation = dragOffset >= maxWidth * 0.5
                                    print("Drag offset: \(dragOffset), Max width: \(maxWidth)")
                                }
                                .onEnded { value in
                                    let maxWidth = UIScreen.main.bounds.width - 80
                                    if dragOffset >= maxWidth * 0.5 {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            onStatusChange("In Progress")
                                            dragOffset = 0
                                            showAnimation = false
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            dragOffset = 0
                                            showAnimation = false
                                        }
                                    }
                                }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
            } else if workOrder.status == "In Progress" {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onStatusChange("Completed")
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.large)
                        Text("Mark as Completed")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            } else if workOrder.status == "Completed" {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.large)
                        .scaleEffect(showAnimation ? 1.2 : 1.0)
                    Text("Finished")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.green)
                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(Color.green.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear {
                    showAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAnimation = false
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .overlay(
                    LinearGradient(
                        colors: [.gray.opacity(0.05), .gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 6, y: 3)
        )
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

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "in progress": return .orange
        case "to be done": return .red
        default: return .secondary
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
