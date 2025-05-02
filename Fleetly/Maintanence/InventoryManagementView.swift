import SwiftUI
import Firebase
import FirebaseFirestore

struct InventoryManagementView: View {
    @StateObject private var viewModel = InventoryViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                    List {
                        ForEach(viewModel.inventoryItems.indices, id: \.self) { index in
                            let item = viewModel.inventoryItems[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.name)
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Units: \(item.units)")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(item.units > 0 ? .gray : .red)
                                }
                                Spacer()
                                HStack(spacing: 15) {
                                    Button(action: {
                                        viewModel.decrementUnits(for: item.id)
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                            .font(.system(size: 20))
                                    }
                                    Button(action: {
                                        viewModel.incrementUnits(for: item.id)
                                    }) {
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.green)
                                            .font(.system(size: 20))
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .background(Color(hex: "F3F3F3").ignoresSafeArea())
            .navigationTitle("Inventory Management")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchInventory()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchInventory() {
        isLoading = true
        listener = db.collection("inventory")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching inventory: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No inventory items found"
                    return
                }
                
                self.inventoryItems = documents.compactMap { document in
                    guard let name = document.data()["name"] as? String,
                          let units = document.data()["units"] as? Int else {
                        return nil
                    }
                    return InventoryItem(id: document.documentID, name: name, units: units)
                }
            }
    }
    
    func incrementUnits(for itemId: String) {
        if let index = inventoryItems.firstIndex(where: { $0.id == itemId }) {
            let newUnits = inventoryItems[index].units + 1
            db.collection("inventory").document(itemId).updateData(["units": newUnits]) { error in
                if let error = error {
                    self.errorMessage = "Error updating units: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func decrementUnits(for itemId: String) {
        if let index = inventoryItems.firstIndex(where: { $0.id == itemId }) {
            let newUnits = max(0, inventoryItems[index].units - 1)
            db.collection("inventory").document(itemId).updateData(["units": newUnits]) { error in
                if let error = error {
                    self.errorMessage = "Error updating units: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct InventoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryManagementView()
    }
}
