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
}

// Main View for the Ticket List
struct TicketListView: View {
    @StateObject private var viewModel = AssignTaskViewModel()
    @StateObject private var ticketManager = TicketManager()
    @State private var isShowingAssignTaskSheet = false
    @State private var selectedTicket: DriverTicket?
    @State private var isLoading = true
    
    var driverTickets: [DriverTicket] {
        ticketManager.tickets.map { ticket in
            DriverTicket(
                id: ticket.id ?? UUID().uuidString,
                title: ticket.category.uppercased(),
                vehicle: ticket.vehicleNumber,
                issue: ticket.issueType,
                date: ticket.date.formattedString(),
                status: ticket.status,
                priority: ticket.priority.uppercased()
            )
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    List {
                        ForEach(driverTickets) { ticket in
                            TicketRow(
                                ticket: ticket,
                                isShowingAssignTaskSheet: $isShowingAssignTaskSheet,
                                selectedTicket: $selectedTicket
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .overlay {
                        if driverTickets.isEmpty {
                            ContentUnavailableView(
                                "No Tickets Available",
                                systemImage: "ticket",
                                description: Text("There are no tickets at the moment.")
                            )
                        }
                    }
                }
            }
            .navigationTitle("My Tickets")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $isShowingAssignTaskSheet) {
                if let selectedTicket = selectedTicket {
                    AssignTaskView()
                }
            }
            .onAppear {
                // Simulate loading time to ensure data is fetched
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
        }
    }
}

// View for each ticket row
struct TicketRow: View {
    let ticket: DriverTicket
    @Binding var isShowingAssignTaskSheet: Bool
    @Binding var selectedTicket: DriverTicket?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ticket.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vehicle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(ticket.vehicle)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Issue Type")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(ticket.issue)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(ticket.date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                // Priority indicator at top-right
                HStack(spacing: 6) {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(priorityColor(priority: ticket.priority))
                    Text(ticket.priority)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(priorityColor(priority: ticket.priority))
                }
                .padding(.bottom, 20)

                // "Schedule" button
                Button(action: {
                    selectedTicket = ticket
                    isShowingAssignTaskSheet = true
                    
                }) {
                    Text("Schedule")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private func priorityColor(priority: String) -> Color {
        switch priority.lowercased() {
        case "low":
            return Color.green
        case "medium":
            return Color.yellow
        case "high":
            return Color.red
        default:
            return Color.gray
        }
    }
}

// Preview Provider
struct TicketListView_Previews: PreviewProvider {
    static var previews: some View {
        TicketListView()
    }
}

//made by pp bhaiiii
