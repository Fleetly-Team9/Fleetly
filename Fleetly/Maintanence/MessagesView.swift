import SwiftUI

struct MessagesView: View {
    @State private var filterSelection = "All"
    let filterOptions = ["All", "Driver", "Fleet Manager"]
    
    let messages = [
        Message(id: 1, sender: "Fleet Manager", time: "9:40 AM", content: "Please provide vehicle history for KA01AB4321"),
        Message(id: 2, sender: "Driver 1", time: "9:36 AM", content: "Repairs cost $200, expect delivery by 6 PM"),
        Message(id: 3, sender: "Driver 2", time: "9:28 AM", content: "Vehicle condition report sent"),
        Message(id: 4, sender: "Fleet Manager", time: "9:20 AM", content: "Schedule maintenance for vehicle KA04GH8765"),
        Message(id: 5, sender: "Driver 3", time: "9:00 AM", content: "Brake pads replaced, awaiting approval"),
        Message(id: 6, sender: "Driver 4", time: "8:50 AM", content: "Oil change completed for KA09EF5678"),
        Message(id: 7, sender: "Fleet Manager", time: "8:40 AM", content: "Update on KA03YZ9087: AC Gas Refill done"),
        Message(id: 8, sender: "Driver 5", time: "8:30 AM", content: "Transmission issues with KA01WX9912"),
        Message(id: 9, sender: "Driver 6", time: "8:20 AM", content: "Window motor fixed for KA03ST8899")
    ]
    
    @State private var selectedSender: String?
    @State private var replyText: String = ""
    
    // Group messages by sender and get the latest message for each
    var conversations: [(sender: String, latestMessage: Message)] {
        // Group messages by sender
        let groupedMessages = Dictionary(grouping: messages, by: { $0.sender })
        
        // Map to an array of (sender, latestMessage), sorted by time
        let sortedConversations = groupedMessages.map { (sender, messages) -> (sender: String, latestMessage: Message) in
            let sortedMessages = messages.sorted { $0.time > $1.time }
            return (sender: sender, latestMessage: sortedMessages.first!)
        }.sorted { $0.latestMessage.time > $1.latestMessage.time }
        
        // Apply filter
        switch filterSelection {
        case "Driver":
            return sortedConversations.filter { $0.sender.contains("Driver") }
        case "Fleet Manager":
            return sortedConversations.filter { $0.sender == "Fleet Manager" }
        default:
            return sortedConversations
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Messages Label with Icons
                HStack {
                    Text("Messages")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Button(action: {
                        print("Plus button tapped")
                    }) {
                        Image(systemName: "plus")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                    
                    Button(action: {
                        print("Camera button tapped")
                    }) {
                        Image(systemName: "camera")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                    
                    Button(action: {
                        print("Photos button tapped")
                    }) {
                        Image(systemName: "photo")
                            .imageScale(.large)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Segmented Control Filter
                Picker("Filter", selection: $filterSelection) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                // List of Conversations
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(conversations, id: \.sender) { conversation in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .center) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 10)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(conversation.sender)
                                            .font(.system(.headline, design: .rounded).weight(.medium))
                                            .foregroundColor(Color(hex: "444444"))
                                        Text(conversation.latestMessage.content)
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(conversation.latestMessage.time)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSender = conversation.sender
                            }
                        }
                    }
                }
                .background(Color.white)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(
                get: { selectedSender != nil },
                set: { if !$0 { selectedSender = nil } }
            )) {
                if let sender = selectedSender {
                    ChatDetailView(sender: sender, messages: messages.filter { $0.sender == sender }, replyText: $replyText)
                }
            }
        }
    }
}

// Detailed Chat View for Each Conversation
struct ChatDetailView: View {
    let sender: String
    let messages: [Message]
    @Binding var replyText: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            Text("Chat with \(sender)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(Color(hex: "444444"))
                .padding(.vertical, 10)
            
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        HStack {
                            if message.sender == "Fleet Manager" {
                                Spacer()
                                Text(message.content)
                                    .padding(10)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(Color(hex: "444444"))
                                Text(message.time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                            } else {
                                Text(message.time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 5)
                                Text(message.content)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(Color(hex: "444444"))
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 60)
            }
            .background(Color.white)
            
            // Input Area
            HStack {
                TextField("Type a reply...", text: $replyText)
                    .padding()
                    .background(Color(hex: "E6E6E6"))
                    .cornerRadius(18)
                Button("Send") {
                    if !replyText.isEmpty {
                        print("Sent to \(sender): \(replyText)")
                        replyText = ""
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(18)
                .disabled(replyText.isEmpty)
            }
            .padding()
            .background(Color(hex: "F9FAFB"))
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

