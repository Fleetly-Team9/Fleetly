//
//  raisedtickets.swift
//  Fleetly
//
//  Created by User@Param on 01/05/25.
//
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

// MARK: - Main Communication View
struct CommunicationView: View {
    @StateObject private var ticketManager = TicketManager()
    @State private var showAddTicket = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        if ticketManager.tickets.isEmpty {
                            Text("No tickets available")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(ticketManager.tickets) { ticket in
                                TicketCardView(ticket: ticket)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
                
                Button(action: {
                    showAddTicket = true
                }) {
                    Text("Raise a Ticket")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle("Communication")
            .sheet(isPresented: $showAddTicket) {
                AddTicketView(ticketManager: ticketManager)
            }
        }
    }
    
    // MARK: - Ticket Card View
    struct TicketCardView: View {
        let ticket: Ticket
        
        var statusColor: Color {
            ticket.status == "Closed" ? .green : .orange
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(ticket.category.uppercased())
                        .font(.headline)
                    Spacer()
                    Text(ticket.status)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .clipShape(Capsule())
                }
                
                Group {
                    HStack {
                        Text("Vehicle Number")
                        Spacer()
                        Text(ticket.vehicleNumber)
                    }
                    
                    HStack {
                        Text("Issue Type")
                        Spacer()
                        Text(ticket.issueType)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(ticket.date)
                    }
                    
                    HStack {
                        Text("Priority")
                        Spacer()
                        Text(ticket.priority)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    CommunicationView()
}
