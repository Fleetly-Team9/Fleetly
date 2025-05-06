import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DisplayTask: Identifiable {
    let id: String
    var task: MaintenanceTask
    let licensePlate: String
    let make: String
    let model: String
}

struct ScheduleView: View {
    @State private var selectedDate = Date()
    @State private var currentMonthOffset = 0
    let today = Date()
    let calendar = Calendar.current
    private let formatter = DateFormatter()
    private let displayFormatter = DateFormatter()
    private let db = Firestore.firestore()

    @State private var tasksByDate: [String: [DisplayTask]] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isLoaderVisible = false // For fade animation

    init() {
        formatter.dateFormat = "dd-MM-yyyy"
        displayFormatter.dateFormat = "MMMM yyyy"
    }

    var startOfMonth: Date {
        let start = calendar.date(byAdding: .month, value: currentMonthOffset, to: today)!
        let components = calendar.dateComponents([.year, .month], from: start)
        return calendar.date(from: components)!
    }

    var daysInMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        return range.count
    }

    var firstDayOfMonth: Int {
        calendar.component(.weekday, from: startOfMonth) - 1 // 0 (Sunday) to 6 (Saturday)
    }

    var selectedTasks: [DisplayTask] {
        let key = formatter.string(from: selectedDate)
        return tasksByDate[key] ?? []
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed Header: Title and Calendar
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
                }
                .background(Color(hex: "F3F3F3"))

                // Scrollable Content: Loader, Error, and Tasks
                ScrollView {
                    VStack(spacing: 10) {
                        if isLoading {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.blue)
                                    .scaleEffect(1.5)
                                    .padding(.bottom, 8)
                                Text("Loading tasks...")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .opacity(isLoaderVisible ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: isLoaderVisible)
                            .onAppear {
                                isLoaderVisible = true
                            }
                            .onDisappear {
                                isLoaderVisible = false
                            }
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            // Task Details
                            VStack(spacing: 10) {
                                if selectedTasks.isEmpty {
                                    Text("No maintenance tasks on this date")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(Color(hex: "444444"))
                                        .padding()
                                } else {
                                    ForEach(selectedTasks, id: \.id) { displayTask in
                                        let task = displayTask.task
                                        let isCompleted = task.status == .completed
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Text(formatter.string(from: selectedDate))
                                                    .font(.system(.caption, design: .rounded))
                                                Spacer()
                                                Menu {
                                                    Button("Pending", action: { updateTaskStatus(taskId: task.id, status: .pending) })
                                                    Button("In Progress", action: { updateTaskStatus(taskId: task.id, status: .inProgress) })
                                                    Button("Completed", action: { updateTaskStatus(taskId: task.id, status: .completed) })
                                                    Button("Cancelled", action: { updateTaskStatus(taskId: task.id, status: .cancelled) })
                                                } label: {
                                                    HStack(spacing: 2) {
                                                        Text(task.status.rawValue.capitalized)
                                                            .font(.system(size: 14, design: .rounded).weight(.medium))
                                                            .foregroundColor(statusColor(for: task.status))
                                                        if isCompleted {
                                                            Image(systemName: "checkmark")
                                                                .font(.system(size: 10))
                                                                .foregroundColor(statusColor(for: task.status))
                                                        }
                                                        Image(systemName: "chevron.down")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.gray)
                                                    }
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(statusBackgroundColor(for: task.status))
                                                    .cornerRadius(6)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                                    )
                                                }
                                                // Priority Tag (Static, No Dropdown)
                                                HStack(spacing: 2) {
                                                    Text(task.priority.capitalized)
                                                        .font(.system(size: 14, design: .rounded).weight(.medium))
                                                        .foregroundColor(priorityColor(for: task.priority))
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(priorityBackgroundColor(for: task.priority))
                                                .cornerRadius(6)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                                )
                                            }
                                            Text("Vehicle: \(displayTask.make) \(displayTask.model)")
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
                                            Text("License Plate: \(displayTask.licensePlate)")
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.gray)
                                            Text("Issue: \(task.issue)")
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
                                            Text("Expected Completion: \(task.completionDate)")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.gray)
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
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "F3F3F3"))
                    .padding(.top, 20) // Added padding to push task cards down
                }
            }
            .background(Color(hex: "F3F3F3").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await fetchTasks()
            }
        }
    }

    func fetchTasks() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                errorMessage = "User not logged in"
                isLoading = false
            }
            print("FetchTasks: No user ID found. User is not logged in.")
            return
        }

        print("FetchTasks: Starting fetch for userId: \(userId)")
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            tasksByDate.removeAll()
        }

        do {
            let snapshot = try await db.collection("maintenance_tasks")
                .whereField("assignedToId", isEqualTo: userId)
                .order(by: "completionDate", descending: false)
                .getDocuments()

            let documents = snapshot.documents
            print("FetchTasks: Found \(documents.count) documents for userId: \(userId)")

            var tempTasks: [String: [DisplayTask]] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd" // Matches the database format for completionDate

            // Batch fetch vehicle details
            let vehicleIds = documents.compactMap { $0.data()["vehicleId"] as? String }
            var vehicleMap: [String: (licensePlate: String, make: String, model: String)] = [:]

            if !vehicleIds.isEmpty {
                let chunks = vehicleIds.chunked(into: 10)
                for chunk in chunks {
                    do {
                        let vehicleSnapshot = try await db.collection("vehicles")
                            .whereField(FieldPath.documentID(), in: chunk)
                            .getDocuments()
                        for doc in vehicleSnapshot.documents {
                            let vehicleData = doc.data()
                            vehicleMap[doc.documentID] = (
                                licensePlate: vehicleData["licensePlate"] as? String ?? "Unknown",
                                make: vehicleData["make"] as? String ?? "Unknown",
                                model: vehicleData["model"] as? String ?? "Unknown"
                            )
                            print("FetchTasks: Fetched vehicle details for vehicleId: \(doc.documentID) - licensePlate: \(vehicleMap[doc.documentID]!.licensePlate), make: \(vehicleMap[doc.documentID]!.make), model: \(vehicleMap[doc.documentID]!.model)")
                        }
                    } catch {
                        print("FetchTasks: Error fetching vehicles for chunk \(chunk): \(error.localizedDescription)")
                    }
                }
            }

            for (index, document) in documents.enumerated() {
                let data = document.data()
                print("FetchTasks: Document \(index + 1) - ID: \(document.documentID), Data: \(data)")

                // Parse completionDate as a string and convert to Date
                guard let completionDateStr = data["completionDate"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing or invalid completionDate: \(String(describing: data["completionDate"]))")
                    continue
                }
                guard let completionDate = dateFormatter.date(from: completionDateStr) else {
                    print("FetchTasks: Document \(document.documentID) - Failed to parse completionDate: \(completionDateStr)")
                    continue
                }
                let dateKey = formatter.string(from: completionDate)
                print("FetchTasks: Document \(document.documentID) - Parsed completionDate: \(completionDateStr) -> \(dateKey)")

                // Get vehicleId and fetch vehicle details from the map
                guard let vehicleId = data["vehicleId"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing vehicleId")
                    continue
                }
                print("FetchTasks: Document \(document.documentID) - vehicleId: \(vehicleId)")

                guard let issue = data["issue"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing issue")
                    continue
                }
                guard let priority = data["priority"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing priority")
                    continue
                }
                guard let assignedToId = data["assignedToId"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing assignedToId")
                    continue
                }
                guard let statusRaw = data["status"] as? String,
                      let status = MaintenanceTask.TaskStatus(rawValue: statusRaw) else {
                    print("FetchTasks: Document \(document.documentID) - Missing or invalid status: \(String(describing: data["status"]))")
                    continue
                }
                guard let createdAt = data["createdAt"] as? String else {
                    print("FetchTasks: Document \(document.documentID) - Missing createdAt")
                    continue
                }

                let vehicleDetails = vehicleMap[vehicleId] ?? (licensePlate: "Unknown", make: "Unknown", model: "Unknown")

                let task = MaintenanceTask(
                    id: document.documentID,
                    vehicleId: vehicleId,
                    issue: issue,
                    completionDate: completionDateStr,
                    priority: priority,
                    assignedToId: assignedToId,
                    status: status,
                    createdAt: createdAt
                )

                let displayTask = DisplayTask(
                    id: task.id,
                    task: task,
                    licensePlate: vehicleDetails.licensePlate,
                    make: vehicleDetails.make,
                    model: vehicleDetails.model
                )

                print("FetchTasks: Document \(document.documentID) - Created DisplayTask: id=\(displayTask.id), vehicleId=\(task.vehicleId), licensePlate=\(displayTask.licensePlate), make=\(displayTask.make), model=\(displayTask.model), issue=\(task.issue), status=\(task.status.rawValue), priority=\(task.priority)")

                if tempTasks[dateKey] == nil {
                    tempTasks[dateKey] = []
                }
                tempTasks[dateKey]?.append(displayTask)
            }

            print("FetchTasks: Final tasksByDate: \(tempTasks)")
            await MainActor.run {
                tasksByDate = tempTasks
                isLoading = false
            }
        } catch {
            await MainActor.run {
                if (error as NSError).localizedDescription.contains("requires an index") || (error as NSError).userInfo["FIRFirestoreErrorIndexURL"] != nil {
                    let indexLink = (error as NSError).userInfo["FIRFirestoreErrorIndexURL"] as? String ?? "Check Firebase Console for index creation."
                    errorMessage = "Query requires an index. Create it here: \(indexLink)"
                    print("FetchTasks: Missing index error. Link: \(indexLink)")
                } else {
                    errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
                    print("FetchTasks: Error fetching tasks: \(error.localizedDescription), userInfo: \((error as NSError).userInfo)")
                }
                isLoading = false
            }
        }
    }

    func updateTaskStatus(taskId: String, status: MaintenanceTask.TaskStatus) {
        db.collection("maintenance_tasks").document(taskId).updateData(["status": status.rawValue]) { error in
            if let error = error {
                print("UpdateTaskStatus: Error updating status for taskId \(taskId): \(error.localizedDescription)")
            } else {
                print("UpdateTaskStatus: Successfully updated status for taskId \(taskId) to \(status.rawValue)")
                // Update local state
                let key = formatter.string(from: selectedDate)
                if let index = tasksByDate[key]?.firstIndex(where: { $0.id == taskId }) {
                    tasksByDate[key]?[index].task.status = status
                }
            }
        }
    }

    func priorityText(for priority: String) -> String {
        return priority.capitalized
    }

    func statusColor(for status: MaintenanceTask.TaskStatus) -> Color {
        switch status {
        case .completed:
            return .green
        case .inProgress:
            return .orange
        case .pending:
            return .blue
        case .cancelled:
            return .gray
        case .archived:
            return .gray
        }
    }

    func statusBackgroundColor(for status: MaintenanceTask.TaskStatus) -> Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.2)
        case .inProgress:
            return Color.orange.opacity(0.2)
        case .pending:
            return Color.blue.opacity(0.2)
        case .cancelled:
            return Color.gray.opacity(0.2)
        case .archived:
            return .gray
        }
    }

    func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "low":
            return .green
        case "medium":
            return .yellow
        case "high":
            return .red
        default:
            return .gray
        }
    }

    func priorityBackgroundColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "low":
            return Color.green.opacity(0.2)
        case "medium":
            return Color.yellow.opacity(0.2)
        case "high":
            return Color.red.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
    }
}

// Extension to chunk arrays for Firestore 'in' query limit
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension DocumentReference {
    func getDocument() async throws -> DocumentSnapshot {
        return try await withCheckedThrowingContinuation { continuation in
            self.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document snapshot is nil"]))
                }
            }
        }
    }
}

extension Query {
    func getDocuments() async throws -> QuerySnapshot {
        return try await withCheckedThrowingContinuation { continuation in
            self.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "Query snapshot is nil"]))
                }
            }
        }
    }
}
