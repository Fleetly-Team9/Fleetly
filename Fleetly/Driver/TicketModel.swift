import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct Ticket: Identifiable, Codable {
    @DocumentID var id: String?
    let category: String
    let status: String
    let vehicleId: String // For database references
    let vehicleNumber: String // For display purposes
    let issueType: String
    let description: String
    let date: Date
    let priority: String
    let photos: [String]? // URLs to photos in Firebase Storage
    let createdBy: String // User ID who created the ticket
    let tripId: String? // Optional trip ID if ticket is related to a trip
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case status
        case vehicleId
        case vehicleNumber
        case issueType
        case description
        case date
        case priority
        case photos
        case createdBy
        case tripId
    }
}

class TicketManager: ObservableObject {
    @Published var tickets: [Ticket] = []
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    
    init() {
        setupTicketListener()
    }
    
    deinit {
        removeListener()
    }
    
    private func setupTicketListener() {
        // For manager view, fetch all tickets
        listener = db.collection("tickets")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching tickets: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.tickets = documents.compactMap { document in
                    try? document.data(as: Ticket.self)
                }
            }
    }
    
    func removeListener() {
        listener?.remove()
        listener = nil
    }
    
    func refreshTickets() {
        removeListener()
        setupTicketListener()
    }
    
    func addTicket(
        category: String,
        vehicleId: String,
        vehicleNumber: String,
        issueType: String,
        description: String,
        priority: String,
        photos: [UIImage]?,
        tripId: String? = nil,
        completion: @escaping (String?) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion("User not authenticated")
            return
        }
        
        // First upload photos if any
        uploadPhotos(photos) { [weak self] photoUrls in
            let ticket = Ticket(
                category: category,
                status: "Open",
                vehicleId: vehicleId,
                vehicleNumber: vehicleNumber,
                issueType: issueType,
                description: description,
                date: Date(),
                priority: priority,
                photos: photoUrls,
                createdBy: userId,
                tripId: tripId
            )
            
            do {
                try self?.db.collection("tickets").addDocument(from: ticket)
                completion(nil) // Success
            } catch {
                completion("Error adding ticket: \(error.localizedDescription)")
            }
        }
    }
    
    private func uploadPhotos(_ photos: [UIImage]?, completion: @escaping ([String]?) -> Void) {
        guard let photos = photos, !photos.isEmpty else {
            completion(nil)
            return
        }
        
        let group = DispatchGroup()
        var uploadedUrls: [String] = []
        
        for (index, photo) in photos.enumerated() {
            group.enter()
            
            guard let imageData = photo.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            let photoId = UUID().uuidString
            let photoRef = storage.reference().child("tickets/\(photoId).jpg")
            
            photoRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading photo: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                
                photoRef.downloadURL { url, error in
                    if let url = url {
                        uploadedUrls.append(url.absoluteString)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(uploadedUrls.isEmpty ? nil : uploadedUrls)
        }
    }
    
    func updateTicketStatus(_ ticketId: String, newStatus: String) {
        let ticketRef = db.collection("tickets").document(ticketId)
        
        ticketRef.updateData([
            "status": newStatus
        ]) { error in
            if let error = error {
                print("Error updating ticket status: \(error.localizedDescription)")
            }
        }
    }
}
