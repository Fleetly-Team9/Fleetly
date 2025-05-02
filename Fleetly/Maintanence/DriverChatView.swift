//
//  DriverChatView.swift
//  Maintenance
//
//  Created by Gunjan Mishra on 26/04/25.
//


import SwiftUI

struct DriverChatView: View {
    @State private var message = ""
    @State private var chatHistory: [String] = ["Driver: Vehicle condition report sent.", "You: Repairs cost $200, expect delivery by 6 PM"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Driver Chat")
                    .font(.system(.title2, design: .default).weight(.bold))
                    .foregroundColor(Color(hex: "444444"))
                    .padding(.top)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chatHistory, id: \.self) { message in
                            Text(message)
                                .padding()
                                .background(Color(hex: "D1D5DB"))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding()
                }

                HStack {
                    TextField("Type a message...", text: $message)
                        .padding()
                        .background(Color(hex: "E6E6E6"))
                        .cornerRadius(8)
                    Button("Send") {
                        if !message.isEmpty {
                            chatHistory.append("You: \(message)")
                            message = ""
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Driver")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

