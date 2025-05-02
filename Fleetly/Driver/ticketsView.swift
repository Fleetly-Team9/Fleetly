//
//  ticketsView.swift
//  Fleetly
//
//  Created by admin40 on 02/05/25.
//

import SwiftUI

// MARK: - Date Formatter Extension
extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Ticket Model

// MARK: - Main Tickets View
struct TicketsView: View {
    @StateObject private var ticketManager = TicketManager()
    @State private var showAddTicket = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if ticketManager.tickets.isEmpty {
                    // Empty State View
                    VStack(spacing: 24) {
                        Spacer()

                        VStack(spacing: 24) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .font(.system(size: 70, weight: .bold))
                                .foregroundStyle(.blue)
                                .scaleEffect(1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: true)

                            Text("No Tickets Yet!")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)

                            Text("Facing an issue? Raise a ticket and we'll help you out.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(36)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)

                        Spacer()
                    }
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
    @State private var showTicketDetails = false

    var statusColor: Color {
        switch ticket.status.lowercased() {
        case "closed":
            return .green
        case "in progress":
            return .blue
        case "open":
            return .orange
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: ticket.date)
    }

    var body: some View {
        Button(action: {
            showTicketDetails = true
        }) {
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
                
                // Description Preview
                if !ticket.description.isEmpty {
                    Text(ticket.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ticket.date.formattedString())
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
        .buttonStyle(.plain)
        .sheet(isPresented: $showTicketDetails) {
            TicketDetailView(ticket: ticket)
        }
    }
}

// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticket: Ticket
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
                        StatusBadge(status: ticket.status)
                        Spacer()
                        PriorityBadge(priority: ticket.priority)
                    }
                    
                    // Category and Date
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Category", systemImage: "tag")
                            .font(.headline)
                        Text(ticket.category)
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
        }
    }
}

// MARK: - Supporting Views
struct StatusBadge: View {
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
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }
}

struct PriorityBadge: View {
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
                .font(.system(.caption, design: .rounded).weight(.medium))
        }
        .foregroundStyle(color)
    }
}

#Preview {
    TicketsView()
}
