import SwiftUI

// MARK: - Ticket Model
struct Ticket: Identifiable {
    let id = UUID()
    let category: String
    let status: String
    let vehicleNumber: String
    let issueType: String
    let date: String
    let priority: String
}

// MARK: - Main Tickets View
struct TicketsView: View {
    @StateObject private var ticketManager = TicketManager()
    @State private var showAddTicket = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if ticketManager.tickets.isEmpty {
                    // Empty State View
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.0)
                                        .repeatForever(autoreverses: true),
                                    value: UUID()
                                )
                                .accessibilityLabel("Ticket icon")

                            Text("No Tickets Available")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)

                            Text("Raise a ticket to report an issue, and we'll assist you promptly.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .accessibilityLabel("Raise a ticket to report an issue")
                        }
                        .padding(24)
                        .frame(maxWidth: 400)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 16)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Support dynamic type

                        Spacer()
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    // List of Tickets
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(ticketManager.tickets) { ticket in
                                TicketCardView(ticket: ticket)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    Button(action: {
                        showAddTicket = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Raise a Ticket")
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.85), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .accessibilityLabel("Raise a new ticket")
                    .accessibilityHint("Opens a form to create a new ticket")
                }
            }
            .navigationTitle("My Tickets")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddTicket) {
                AddTicketView(ticketManager: ticketManager)
            }
        }
    }
}

// MARK: - Ticket Card View
struct TicketCardView: View {
    let ticket: Ticket
    @Environment(\.colorScheme) var colorScheme

    var statusColor: Color {
        switch ticket.status.lowercased() {
        case "closed":
            return .green
        case "in progress":
            return .blue
        case "pending":
            return .blue.opacity(0.7)
        default:
            return .gray
        }
    }

    var priorityColor: Color {
        switch ticket.priority.lowercased() {
        case "high":
            return .red
        case "medium":
            return .orange
        case "low":
            return .green
        default:
            return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(ticket.category.uppercased())
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(ticket.status)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .clipShape(Capsule())
            }

            // Vehicle and Issue
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vehicle")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(ticket.vehicleNumber)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.primary)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Issue Type")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(ticket.issueType)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.primary)
                }
            }

            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ticket.date)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(priorityColor)
                    Text(ticket.priority)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(priorityColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    TicketsView()
}
