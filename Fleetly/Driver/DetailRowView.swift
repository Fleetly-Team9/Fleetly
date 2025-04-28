//
//  DetailRowView.swift
//  historyTab
//
//  Created by Sayal Singh on 24/04/25.
//
import SwiftUI

struct DetailRowView: View {
    let title: String
    let value: String
    var valueColor: Color?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.body)
                    .padding(.leading)
                
                Spacer()
                
                Text(value)
                    .font(.body)
                    .foregroundColor(valueColor ?? (colorScheme == .dark ? .white : .black))
                    .multilineTextAlignment(.trailing)
                    .padding(.trailing)
            }
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(colorScheme == .dark ? Color(UIColor.systemGray4) : Color.white)
    }
}
