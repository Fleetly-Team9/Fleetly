//
//  ExpenseButton.swift
//  FleetlyDriver
//
//  Created by Sayal Singh on 25/04/25.
//

import SwiftUI

struct ExpenseButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ExpenseButton(icon: "fuelpump.fill", title: "Fuel Log", action: {})
}
