//
//  TicketManager.swift
//  Fleetly
//
//  Created by User@Param on 01/05/25.
//
import Foundation

class TicketManager: ObservableObject {
    @Published var tickets: [Ticket] = []
    
    func addTicket(vehicleNumber: String, issueType: String, description: String, priority: String) {
        let newTicket = Ticket(
            category: issueType,
            status: "In Progress",
            vehicleNumber: vehicleNumber,
            issueType: issueType,
            date: formattedDate(),
            priority: priority
        )
        tickets.append(newTicket)
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }
}
 
