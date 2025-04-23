import Foundation
import Firebase
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    let db = Firestore.firestore()

    private init() { /* FirebaseApp.configure() is called in App init */ }

    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(id).getDocument { snap, err in
            if let err = err {
                completion(.failure(err)); return
            }
            guard var data = snap?.data() else {
                completion(.failure(NSError(
                    domain: "", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No user data"]
                )))
                return
            }
            // Inject the document ID so Codable can map it to `id`
            data["uid"] = id
            do {
                let json = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(User.self, from: json)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func saveUser(_ user: User, completion: @escaping (Error?) -> Void) {
        do {
            // Encoder will emit "uid" key for user.id
            var data = try Firestore.Encoder().encode(user)
            // Remove the "uid" field so it isn't stored redundantly
            data["uid"] = nil
            db.collection("users").document(user.id)
              .setData(data, completion: completion)
        } catch {
            completion(error)
        }
    }
}
