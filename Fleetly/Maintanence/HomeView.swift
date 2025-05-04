import SwiftUI

struct HomeView: View {
    @State private var workOrders: [WorkOrder] = [
        WorkOrder(id: "23", vehicleNumber: "KA01AB4321", issue: "Brake Pad Replacement", status: "To be Done", expectedDelivery: "6:00 PM", priority: 2, issues: ["Worn brake pads"], parts: []),
        WorkOrder(id: "24", vehicleNumber: "KA02CD9876", issue: "Oil Change", status: "To be Done", expectedDelivery: "7:00 PM", priority: 1, issues: ["Low oil"], parts: []),
        WorkOrder(id: "25", vehicleNumber: "KA03EF5432", issue: "Tire Rotation", status: "To be Done", expectedDelivery: "8:00 PM", priority: 0, issues: ["Uneven wear"], parts: [])
    ]
    @State private var showCardAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                        .accessibilityLabel("Profile")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Overview Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            OverviewStat(icon: "car.fill", title: "Total Vehicles", value: "19", color: Color(hex: "#007AFF"))
                            OverviewStat(icon: "wrench.and.screwdriver.fill", title: "Pending   Tasks", value: "5", color: Color(hex: "#FF9500"))
                        }
                        .padding(.horizontal, 16)
                    }

                    // Assigned Work Section
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink(destination: AllTasksView(workOrders: $workOrders)) {
                            HStack {
                                Text("Assigned Work")
                                    .font(.system(.title3, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(.title3, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                        }
                        .accessibilityLabel("View All Tasks")

                        if workOrders.isEmpty {
                            VStack {
                                Spacer()
                                Text("No Assignments")
                                    .font(.system(.title3, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.background)
                                            .overlay(.ultraThinMaterial)
                                            .shadow(radius: 2)
                                    )
                                    .padding(.horizontal, 24)
                                Spacer()
                            }
                        } else {
                            ForEach($workOrders, id: \.id) { $workOrder in
                                WorkOrderCard(
                                    workOrder: $workOrder,
                                    onStatusChange: { newStatus in
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            workOrder.status = newStatus
                                            if newStatus == "Completed" {
                                                if let index = workOrders.firstIndex(where: { $0.id == workOrder.id }) {
                                                    workOrders.remove(at: index)
                                                }
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                                .opacity(showCardAnimation ? 1 : 0)
                                .offset(y: showCardAnimation ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.5).delay(Double(workOrders.firstIndex(where: { $0.id == workOrder.id }) ?? 0) * 0.1),
                                    value: showCardAnimation
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
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
        "Manash"
    }
}

struct AllTasksView: View {
    @Binding var workOrders: [WorkOrder]
    @State private var selectedDayFilter: String = "All"
    @State private var showCardAnimation = false

    var filteredWorkOrders: [WorkOrder] {
        workOrders.filter { workOrder in
            let dayMatch: Bool
            switch selectedDayFilter {
            case "Today":
                dayMatch = workOrder.expectedDelivery != nil
            case "Tomorrow":
                dayMatch = workOrder.expectedDelivery == nil
            default:
                dayMatch = true
            }
            return dayMatch
        }
    }

    var uniqueIssues: [String] {
        Array(Set(workOrders.flatMap { $0.issues })).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if filteredWorkOrders.isEmpty {
                    Text("No Tasks Match Filters")
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
                        if filteredWorkOrders.contains(where: { $0.id == workOrder.id }) {
                            WorkOrderCard(
                                workOrder: $workOrder,
                                onStatusChange: { newStatus in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        workOrder.status = newStatus
                                        if newStatus == "Completed" {
                                            if let index = workOrders.firstIndex(where: { $0.id == workOrder.id }) {
                                                workOrders.remove(at: index)
                                            }
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .opacity(showCardAnimation ? 1 : 0)
                            .offset(y: showCardAnimation ? 0 : 20)
                            .animation(
                                .easeOut(duration: 0.5).delay(Double(filteredWorkOrders.firstIndex(where: { $0.id == workOrder.id }) ?? 0) * 0.1),
                                value: showCardAnimation
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("All Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section(header: Text("Filter by Day")) {
                        Button("All") { selectedDayFilter = "All" }
                        Button("Today") { selectedDayFilter = "Today" }
                        Button("Tomorrow") { selectedDayFilter = "Tomorrow" }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Filter Tasks")
            }
        }
        .onAppear {
            withAnimation {
                showCardAnimation = true
            }
        }
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
                .font(.system(size: 24, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(radius: 2)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title2, design: .default, weight: .bold))
                    .foregroundStyle(.primary)
                Text(title.uppercased())
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: (UIScreen.main.bounds.width - 48) / 2, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    LinearGradient(
                        colors: [color.opacity(0.05), color.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
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
                Text("Work Order \(workOrder.id)")
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

            // Action (All Swipable)
            GeometryReader { geometry in
                VStack(spacing: 12) {
                    Text(swipeActionText(workOrder.status))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(swipeActionColor(workOrder.status))

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(height: 50)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(swipeActionColor(workOrder.status).opacity(showAnimation ? 0.5 : 0.3))
                            .frame(width: max(0, dragOffset), height: 50)

                        // Slider Knob
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 42, height: 42)
                                .shadow(radius: 2)
                            Image(systemName: swipeActionIcon(workOrder.status))
                                .foregroundStyle(showAnimation ? swipeActionColor(workOrder.status) : .gray)
                                .imageScale(.medium)
                                .scaleEffect(showAnimation ? 1.2 : 1.0)
                        }
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let maxWidth = geometry.size.width - 42 // Account for knob width
                                    dragOffset = min(max(value.translation.width, 0), maxWidth)
                                    showAnimation = dragOffset >= maxWidth * 0.6
                                    if showAnimation {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                    }
                                }
                                .onEnded { value in
                                    let maxWidth = geometry.size.width - 42
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        if dragOffset >= maxWidth * 0.6 {
                                            handleSwipeAction()
                                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                                            impact.impactOccurred()
                                        }
                                        dragOffset = 0
                                        showAnimation = false
                                    }
                                }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .accessibilityLabel("\(swipeActionText(workOrder.status)) for work order \(workOrder.id)")
                }
            }
            .frame(height: 86) // Fixed height to accommodate the slider and text
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .overlay(
                    LinearGradient(
                        colors: [.gray.opacity(0.03), .gray.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4, y: 2)
        )
    }

    // Helper functions for status and priority
    private func statusIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "completed": return "checkmark.circle.fill"
        case "in progress": return "gearshape.fill"
        case "to be done": return "hourglass"
        default: return "questionmark.circle"
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

    private func priorityIcon(_ priority: Int) -> String {
        switch priority {
        case 0: return "arrow.down.circle"
        case 1: return "arrow.right.circle"
        case 2: return "arrow.up.circle"
        default: return "arrow.down.circle"
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

    private func priorityText(_ priority: Int) -> String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Low"
        }
    }

    // Swipe Action Helpers
    private func swipeActionText(_ status: String) -> String {
        switch status.lowercased() {
        case "to be done": return "Slide to Start"
        case "in progress": return "Slide to Complete"
        case "completed": return "Slide to Archive"
        default: return "Slide to Proceed"
        }
    }

    private func swipeActionIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "to be done": return "wrench.fill"
        case "in progress": return "checkmark.circle.fill"
        case "completed": return "archivebox.fill"
        default: return "arrow.right"
        }
    }

    private func swipeActionColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "to be done": return .blue
        case "in progress": return .blue
        case "completed": return .green
        default: return .gray
        }
    }

    private func handleSwipeAction() {
        switch workOrder.status.lowercased() {
        case "to be done":
            onStatusChange("In Progress")
        case "in progress":
            onStatusChange("Completed")
        case "completed":
            onStatusChange("Archived") // Adjust as needed for your workflow
        default:
            break
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
