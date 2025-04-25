import Foundation
import _PhotosUI_SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()
    let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
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
    func uploadPhoto(item: PhotosPickerItem?,
                         path: String,
                         completion: @escaping (Result<String, Error>) -> Void) {
            guard let item = item else {
                completion(.success(""))  // no photo chosen
                return
            }
            // Load Data from picker
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .failure(let err):
                    completion(.failure(err))
                case .success(let data):
                    guard let data = data else {
                        completion(.failure(NSError(domain:"", code:-1, userInfo:[NSLocalizedDescriptionKey:"No image data"])))
                        return
                    }
                    let ref = self.storage.child(path)
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    ref.putData(data, metadata: metadata) { _, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        ref.downloadURL { url, error in
                            if let url = url {
                                completion(.success(url.absoluteString))
                            } else {
                                completion(.failure(error!))
                            }
                        }
                    }
                }
            }
        }
}
