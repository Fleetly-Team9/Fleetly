import SwiftUI
import UIKit

struct HomeView: View {
    @State private var showingUpdateUnits = false
    @State private var selectedItem: InventoryItem?
    @State private var unitsToUpdate: Int = 5

    @State private var workOrders: [WorkOrder] = [
        WorkOrder(id: 23, vehicleNumber: "KA01AB4321", issue: "Brake Pad Replacement", status: "To be Done", expectedDelivery: "6:00 PM", priority: 2, issues: ["Worn brake pads"]),
        WorkOrder(id: 24, vehicleNumber: "KA02CD9876", issue: "Oil Change", status: "To be Done", expectedDelivery: "7:00 PM", priority: 1, issues: ["Low oil"]),
        WorkOrder(id: 25, vehicleNumber: "KA03EF5432", issue: "Tire Rotation", status: "To be Done", expectedDelivery: "8:00 PM", priority: 0, issues: ["Uneven wear"])
    ]

    @State private var currentWorkOrderIndex: Int = 0
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiping: Bool = false

    @State private var inventoryItems = [
        InventoryItem(id: 1, name: "Brake Pads", units: 12),
        InventoryItem(id: 2, name: "Oil Filter", units: 0),
        InventoryItem(id: 3, name: "Air Filter", units: 17),
        InventoryItem(id: 4, name: "Spark Plug", units: 20),
        InventoryItem(id: 5, name: "Battery", units: 6),
        InventoryItem(id: 6, name: "Clutch Plate", units: 9)
    ]

    // --- THE FIX: Per-workorder slider state ---
    @State private var sliderOffsets: [Int: CGFloat] = [:]
    @State private var sliderAnimations: [Int: Bool] = [:]

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

                        if currentWorkOrderIndex < workOrders.count {
                            let workOrder = workOrders[currentWorkOrderIndex]
                            WorkOrderCard(
                                workOrder: $workOrders[currentWorkOrderIndex],
                                onStatusChange: { newStatus, workOrderId in
                                    if let index = workOrders.firstIndex(where: { $0.id == workOrderId }) {
                                        workOrders[index].status = newStatus
                                        if newStatus == "Completed" {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                isSwiping = true
                                                swipeOffset = -UIScreen.main.bounds.width
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                    if currentWorkOrderIndex < workOrders.count - 1 {
                                                        currentWorkOrderIndex += 1
                                                    }
                                                    swipeOffset = UIScreen.main.bounds.width
                                                    swipeOffset = 0
                                                    isSwiping = false
                                                }
                                            }
                                        }
                                    }
                                },
                                dragOffset: Binding(
                                    get: { sliderOffsets[workOrder.id] ?? 0 },
                                    set: { sliderOffsets[workOrder.id] = $0 }
                                ),
                                showAnimation: Binding(
                                    get: { sliderAnimations[workOrder.id] ?? false },
                                    set: { sliderAnimations[workOrder.id] = $0 }
                                )
                            )
                            .offset(x: swipeOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isSwiping {
                                            swipeOffset = value.translation.width
                                        }
                                    }
                                    .onEnded { value in
                                        if !isSwiping && swipeOffset < -50 {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                isSwiping = true
                                                workOrders[currentWorkOrderIndex].status = "Completed"
                                                swipeOffset = -UIScreen.main.bounds.width
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                    if currentWorkOrderIndex < workOrders.count - 1 {
                                                        currentWorkOrderIndex += 1
                                                    }
                                                    swipeOffset = UIScreen.main.bounds.width
                                                    swipeOffset = 0
                                                    isSwiping = false
                                                }
                                            }
                                        } else {
                                            withAnimation(.spring()) {
                                                swipeOffset = 0
                                            }
                                        }
                                    }
                            )
                            .onChange(of: workOrders[currentWorkOrderIndex].status) { oldValue, newValue in
                                if newValue == "Completed" && !isSwiping {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        isSwiping = true
                                        swipeOffset = -UIScreen.main.bounds.width
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            if currentWorkOrderIndex < workOrders.count - 1 {
                                                currentWorkOrderIndex += 1
                                            }
                                            swipeOffset = UIScreen.main.bounds.width
                                            swipeOffset = 0
                                            isSwiping = false
                                        }
                                    }
                                }
                            }
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
                            NavigationLink("View All", destination: InventoryManagementView(items: $inventoryItems))
                                .font(.system(.subheadline, design: .rounded).weight(.medium))
                                .foregroundColor(.customBlue)
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 16) {
                            ForEach(inventoryItems.prefix(4)) { item in
                                InventoryIcon(item: item)
                                    .background(Color.backgroundGray)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                        .frame(width: 353, height: 120)
                        .padding(.horizontal, 20)
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

// --- WorkOrderCard now uses only the passed-in bindings for slider state ---
struct WorkOrderCard: View {
    @Binding var workOrder: WorkOrder
    var onStatusChange: (String, Int) -> Void

    @Binding var dragOffset: CGFloat
    @Binding var showAnimation: Bool

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
                let components = !workOrder.issues.isEmpty ? workOrder.issues : workOrder.parts
                if !components.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .imageScale(.small)
                        Text("Issues: \(components.joined(separator: ", "))")
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
            if workOrder.status == "To be Done" {
                VStack(spacing: 8) {
                    // Label above the slider
                    Text("Slide to Start")
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)

                    ZStack(alignment: .leading) {
                        // Slider track
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.lightGray)
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        // Gradient fill
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gradientStart, Color.gradientEnd]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: min(max(dragOffset, 0), UIScreen.main.bounds.width - 60), height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Draggable handle
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                            Image(systemName: "wrench.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(dragOffset >= 120 ? .todayGreen : .darkGray)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    withAnimation(.spring(response: 0.1, dampingFraction: 0.7)) {
                                        dragOffset = min(max(value.translation.width, 0), UIScreen.main.bounds.width - 60)
                                    }
                                    if dragOffset >= 120 {
                                        showAnimation = true
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    } else {
                                        showAnimation = false
                                    }
                                }
                                .onEnded { value in
                                    if dragOffset >= 120 {
                                        workOrder.status = "In Progress"
                                        onStatusChange("In Progress", workOrder.id)
                                        DispatchQueue.main.async {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                dragOffset = 0
                                                showAnimation = false
                                            }
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            dragOffset = 0
                                            showAnimation = false
                                        }
                                    }
                                }
                        )
                        .scaleEffect(showAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: showAnimation)
                    }
                    .frame(height: 48)
                }
            } else if workOrder.status == "In Progress" {
                Button(action: {
                    workOrder.status = "Completed"
                    onStatusChange("Completed", workOrder.id)
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
            } else if workOrder.status == "Completed" {
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

