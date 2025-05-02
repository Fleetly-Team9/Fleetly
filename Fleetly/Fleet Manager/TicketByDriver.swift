import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// Model for a Driver Ticket
struct DriverTicket: Identifiable {
    let id: String
    let title: String
    let vehicle: String
    let issue: String
    let date: String
    let status: String
    let priority: String
    let driverName: String
}

// Main View for the Ticket List
struct TicketListView: View {
    @StateObject private var viewModel = AssignTaskViewModel()
    @StateObject private var ticketManager = TicketManager()
    @State private var isLoading = true
    @State private var selectedTicket: Ticket?
    @State private var driverNames: [String: String] = [:]
    @State private var showingFilters = false
    @State private var selectedStatus: String?
    @State private var selectedPriority: String?
    @State private var selectedCategory: String?
    @State private var dateRange: ClosedRange<Date> = Calendar.current.date(byAdding: .month, value: -1, to: Date())!...Date()
    
    var filteredTickets: [DriverTicket] {
        var filtered = driverTickets
        
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status.lowercased() == status.lowercased() }
        }
        
        if let priority = selectedPriority {
            filtered = filtered.filter { $0.priority.lowercased() == priority.lowercased() }
        }
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.title.lowercased() == category.lowercased() }
        }
        
        return filtered
    }
    
    var driverTickets: [DriverTicket] {
        ticketManager.tickets.map { ticket in
            let driverName = driverNames[ticket.createdBy] ?? "Unknown Driver"
            print("Using driver name for ticket \(ticket.id ?? "unknown"): \(driverName)")
            return DriverTicket(
                id: ticket.id ?? UUID().uuidString,
                title: ticket.category.uppercased(),
                vehicle: ticket.vehicleNumber,
                issue: ticket.issueType,
                date: ticket.date.formattedString(),
                status: ticket.status,
                priority: ticket.priority.uppercased(),
                driverName: driverName
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                if selectedStatus != nil || selectedPriority != nil || selectedCategory != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: {
                                selectedStatus = nil
                                selectedPriority = nil
                                selectedCategory = nil
                            }) {
                                Label("Clear All", systemImage: "xmark.circle.fill")
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            }
                            
                            if let status = selectedStatus {
                                FilterChip(text: status, color: .blue) {
                                    selectedStatus = nil
                                }
                            }
                            
                            if let priority = selectedPriority {
                                FilterChip(text: priority, color: .orange) {
                                    selectedPriority = nil
                                }
                            }
                            
                            if let category = selectedCategory {
                                FilterChip(text: category, color: .green) {
                                    selectedCategory = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                }
                
                TicketListContent(
                    isLoading: isLoading,
                    driverTickets: filteredTickets,
                    selectedTicket: $selectedTicket,
                    ticketManager: ticketManager,
                    driverNames: driverNames
                )
            }
            .navigationTitle("Tickets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterVieww(
                    selectedStatus: $selectedStatus,
                    selectedPriority: $selectedPriority,
                    selectedCategory: $selectedCategory,
                    dateRange: $dateRange,
                    availableCategories: Array(Set(driverTickets.map { $0.title }))
                )
            }
            .onAppear {
                // Simulate loading time to ensure data is fetched
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                    fetchDriverNames()
                }
            }
            .onChange(of: ticketManager.tickets) { _ in
                fetchDriverNames()
            }
            .sheet(item: $selectedTicket) { ticket in
                DetailTicketView(
                    ticket: ticket,
                    driverName: driverNames[ticket.createdBy] ?? "Unknown Driver"
                )
            }
        }
    }
    
    private func fetchDriverNames() {
        let db = Firestore.firestore()
        let uniqueDriverIds = Set(ticketManager.tickets.map { $0.createdBy })
        
        print("Fetching names for driver IDs: \(uniqueDriverIds)")
        
        for driverId in uniqueDriverIds {
            db.collection("users").document(driverId).getDocument { document, error in
                if let error = error {
                    print("Error fetching driver name for ID \(driverId): \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists else {
                    print("No document found for driver ID: \(driverId)")
                    return
                }
                
                guard let data = document.data() else {
                    print("No data found for driver ID: \(driverId)")
                    return
                }
                
                print("Raw data for driver \(driverId): \(data)")
                
                // Try different possible field names for first and last name
                let firstName = data["firstName"] as? String ?? data["first_name"] as? String ?? data["name"] as? String
                let lastName = data["lastName"] as? String ?? data["last_name"] as? String
                
                if let firstName = firstName {
                    let fullName = lastName != nil ? "\(firstName) \(lastName!)" : firstName
                    print("Found name for driver \(driverId): \(fullName)")
                    DispatchQueue.main.async {
                        self.driverNames[driverId] = fullName
                    }
                } else {
                    print("Could not find name fields for driver ID: \(driverId)")
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct TicketListContent: View {
    let isLoading: Bool
    let driverTickets: [DriverTicket]
    @Binding var selectedTicket: Ticket?
    let ticketManager: TicketManager
    let driverNames: [String: String]
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TicketListViewContent(
                    driverTickets: driverTickets,
                    selectedTicket: $selectedTicket,
                    ticketManager: ticketManager
                )
            }
        }
    }
}

struct TicketListViewContent: View {
    let driverTickets: [DriverTicket]
    @Binding var selectedTicket: Ticket?
    let ticketManager: TicketManager
    
    var body: some View {
        List {
            ForEach(driverTickets) { ticket in
                TicketRow(ticket: ticket)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                        if let originalTicket = ticketManager.tickets.first(where: { $0.id == ticket.id }) {
                            selectedTicket = originalTicket
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
        .overlay {
            if driverTickets.isEmpty {
                ContentUnavailableView {
                    Label("No Tickets", systemImage: "ticket")
                } description: {
                    Text("There are no tickets matching your current filters.")
                } actions: {
                    Button("Clear Filters") {
                        // Clear filters action
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct TicketRow: View {
    let ticket: DriverTicket
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.title)
                        .font(.headline)
                    Text("By: \(ticket.driverName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    StatusBadgee(status: ticket.status)
                    PriorityBadgee(priority: ticket.priority)
                }
            }
            
            // Vehicle and Issue Info
            HStack(spacing: 16) {
                InfoColumn(title: "Vehicle", value: ticket.vehicle)
                InfoColumn(title: "Issue Type", value: ticket.issue)
            }
            
            // Date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(ticket.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct InfoColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Ticket Detail View
struct DetailTicketView: View {
    let ticket: Ticket
    let driverName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var ticketManager = TicketManager()
    @State private var showingStatusUpdateAlert = false
    @State private var newStatus: String = ""
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: ticket.date)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status and Priority
                    HStack {
                        StatusBadgee(status: ticket.status)
                        Spacer()
                        PriorityBadgee(priority: ticket.priority)
                    }
                    
                    // Category and Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Category", systemImage: "tag")
                            .font(.headline)
                        Text(ticket.category)
                            .font(.subheadline)
                    }
                    
                    // Driver Name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reported By", systemImage: "person")
                            .font(.headline)
                        Text(driverName)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date Reported", systemImage: "calendar")
                            .font(.headline)
                        Text(ticket.date.formattedString())
                            .font(.subheadline)
                    }
                    
                    // Vehicle Details
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Vehicle", systemImage: "car")
                            .font(.headline)
                        Text(ticket.vehicleNumber)
                            .font(.subheadline)
                    }
                    
                    // Issue Details
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Issue Type", systemImage: "wrench.and.screwdriver")
                            .font(.headline)
                        Text(ticket.issueType)
                            .font(.subheadline)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Description", systemImage: "text.alignleft")
                            .font(.headline)
                        Text(ticket.description)
                            .font(.subheadline)
                    }
                    
                    // Photos
                    if let photos = ticket.photos, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Photos", systemImage: "photo")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos, id: \.self) { photoUrl in
                                        AsyncImage(url: URL(string: photoUrl)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Status Update Section
                    if ticket.status.lowercased() != "closed" {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update Status")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    newStatus = "In Progress"
                                    showingStatusUpdateAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .symbolRenderingMode(.hierarchical)
                                            .font(.headline)
                                        Text("Mark In Progress")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                
                                Button(action: {
                                    newStatus = "Closed"
                                    showingStatusUpdateAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                            .symbolRenderingMode(.hierarchical)
                                            .font(.headline)
                                        Text("Close Ticket")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundStyle(.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Ticket Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Update Ticket Status", isPresented: $showingStatusUpdateAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Update", role: .none) {
                    updateTicketStatus()
                }
            } message: {
                Text("Are you sure you want to change the status to '\(newStatus)'?")
            }
        }
    }
    
    private func updateTicketStatus() {
        guard let ticketId = ticket.id else { return }
        
        let db = Firestore.firestore()
        db.collection("tickets").document(ticketId).updateData([
            "status": newStatus,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error updating ticket status: \(error.localizedDescription)")
            } else {
                print("Ticket status updated successfully")
                dismiss()
            }
        }
    }
}

// MARK: - Filter Views
struct FilterChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.footnote.weight(.medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.footnote)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

struct FilterVieww: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStatus: String?
    @Binding var selectedPriority: String?
    @Binding var selectedCategory: String?
    @Binding var dateRange: ClosedRange<Date>
    let availableCategories: [String]
    
    private let statuses = ["Open", "In Progress", "Closed"]
    private let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(statuses, id: \.self) { status in
                        FilterRow(
                            title: status,
                            isSelected: selectedStatus == status,
                            action: {
                                selectedStatus = selectedStatus == status ? nil : status
                            }
                        )
                    }
                } header: {
                    Text("Status")
                }
                
                Section {
                    ForEach(priorities, id: \.self) { priority in
                        FilterRow(
                            title: priority,
                            isSelected: selectedPriority == priority,
                            action: {
                                selectedPriority = selectedPriority == priority ? nil : priority
                            }
                        )
                    }
                } header: {
                    Text("Priority")
                }
                
                Section {
                    ForEach(availableCategories, id: \.self) { category in
                        FilterRow(
                            title: category,
                            isSelected: selectedCategory == category,
                            action: {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                } header: {
                    Text("Category")
                }
                
                Section {
                    DatePicker("From", selection: Binding(
                        get: { dateRange.lowerBound },
                        set: { dateRange = $0...dateRange.upperBound }
                    ), displayedComponents: .date)
                    
                    DatePicker("To", selection: Binding(
                        get: { dateRange.upperBound },
                        set: { dateRange = dateRange.lowerBound...$0 }
                    ), displayedComponents: .date)
                } header: {
                    Text("Date Range")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Badges
struct StatusBadgee: View {
    let status: String
    
    var color: Color {
        switch status.lowercased() {
        case "closed": return .green
        case "in progress": return .blue
        case "open": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

struct PriorityBadgee: View {
    let priority: String
    
    var color: Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(priority)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(color)
    }
}

// Preview Provider
struct TicketListView_Previews: PreviewProvider {
    static var previews: some View {
        TicketListView()
    }
}
