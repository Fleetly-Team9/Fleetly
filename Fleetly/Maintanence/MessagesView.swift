import SwiftUI
import Firebase
import FirebaseFirestore

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var newMessage: String = ""

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessagesViewMessageRow(message: message) // Updated to new struct name
                            }
                        }
                        .padding()
                    }
                }

                HStack {
                    TextField("Type a message...", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: {
                        if !newMessage.isEmpty {
                            viewModel.sendMessage(content: newMessage)
                            newMessage = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
            }
            .background(Color(hex: "F3F3F3").ignoresSafeArea())
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MessagesViewMessageRow: View { // Renamed to avoid conflict
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.sender)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(message.time)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.gray)
                }
                Text(message.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchMessages()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchMessages() {
        isLoading = true
        listener = db.collection("messages")
            .whereField("recipientId", isEqualTo: "maintenance_user_id") // Replace with actual user ID
            .order(by: "time", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching messages: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No messages found"
                    return
                }
                
                self.messages = documents.compactMap { document in
                    guard let sender = document.data()["sender"] as? String,
                          let time = document.data()["time"] as? String,
                          let content = document.data()["content"] as? String else {
                        return nil
                    }
                    return Message(id: document.documentID, sender: sender, time: time, content: content)
                }
            }
    }
    
    func sendMessage(content: String) {
        let newMessage = [
            "sender": "maintenance_user_id", // Replace with actual user ID
            "recipientId": "fleet_manager_id", // Replace with actual fleet manager ID
            "time": ISO8601DateFormatter().string(from: Date()),
            "content": content
        ] as [String: Any]
        
        db.collection("messages").addDocument(data: newMessage) { error in
            if let error = error {
                self.errorMessage = "Error sending message: \(error.localizedDescription)"
            }
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}
