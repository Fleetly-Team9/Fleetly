import Foundation
import FirebaseFirestore
import FirebaseStorage

class InventoryManager {
    static let shared = InventoryManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    func fetchInventoryItems(completion: @escaping (Result<[Inventory.Item], Error>) -> Void) {
        db.collection("inventory")
            .order(by: "name")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let items = documents.compactMap { document -> Inventory.Item? in
                    let data = document.data()
                    return Inventory.Item(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        units: data["units"] as? Int ?? 0,
                        minUnits: data["minUnits"] as? Int ?? 5,
                        lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                
                completion(.success(items))
            }
    }
    
    func addInventoryItem(_ item: Inventory.Item, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "name": item.name,
            "units": item.units,
            "minUnits": item.minUnits,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        db.collection("inventory").document(item.id).setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateInventoryItem(_ item: Inventory.Item, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "name": item.name,
            "units": item.units,
            "minUnits": item.minUnits,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        db.collection("inventory").document(item.id).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteInventoryItem(_ itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("inventory").document(itemId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Inventory History
    
    func recordInventoryChange(itemId: String, oldUnits: Int, newUnits: Int, changedBy: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "itemId": itemId,
            "oldUnits": oldUnits,
            "newUnits": newUnits,
            "changedBy": changedBy,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("inventory_history").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getInventoryHistory(for itemId: String, completion: @escaping (Result<[Inventory.HistoryItem], Error>) -> Void) {
        db.collection("inventory_history")
            .whereField("itemId", isEqualTo: itemId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let historyItems = documents.compactMap { document -> Inventory.HistoryItem? in
                    let data = document.data()
                    return Inventory.HistoryItem(
                        id: document.documentID,
                        itemId: data["itemId"] as? String ?? "",
                        oldUnits: data["oldUnits"] as? Int ?? 0,
                        newUnits: data["newUnits"] as? Int ?? 0,
                        changedBy: data["changedBy"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                
                completion(.success(historyItems))
            }
    }
} 