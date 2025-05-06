import SwiftUI
import FirebaseFirestore

struct InventoryManagementView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var selectedItemId: String?
    @State private var isSheetPresented = false
    @State private var showRowAnimation = false
    @State private var isAddItemSheetPresented = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Text("Inventory Management")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                isAddItemSheetPresented = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 28))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Inventory List
                        if viewModel.items.isEmpty {
                            Text("No Items in Inventory")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.background)
                                        .overlay(.ultraThinMaterial)
                                        .shadow(radius: 2)
                                )
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(viewModel.items) { item in
                                InventoryRow(
                                    item: item,
                                    onUpdate: {
                                        selectedItemId = item.id
                                        isSheetPresented = true
                                    }
                                )
                                .padding(.horizontal, 16)
                                .opacity(showRowAnimation ? 1 : 0)
                                .offset(y: showRowAnimation ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.5).delay(Double(viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1),
                                    value: showRowAnimation
                                )
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .background(Color(.systemBackground).ignoresSafeArea())
                .navigationTitle("")
                .navigationBarHidden(true)
                .onAppear {
                    withAnimation {
                        showRowAnimation = true
                    }
                    viewModel.fetchItems()
                }
                .refreshable {
                    viewModel.fetchItems()
                }

                // Update Sheet Overlay
                if isSheetPresented, let id = selectedItemId, let item = viewModel.items.first(where: { $0.id == id }) {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    UpdateSheet(
                        item: item,
                        onClose: {
                            withAnimation {
                                isSheetPresented = false
                                selectedItemId = nil
                            }
                        },
                        onUpdate: { newUnits, newPrice in
                            viewModel.updateItemUnits(itemId: item.id, newUnits: newUnits, newPrice: newPrice)
                        }
                    )
                    .frame(width: 250, height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .zIndex(1)
                }

                // Add Item Sheet Overlay
                if isAddItemSheetPresented {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)

                    AddItemSheet(
                        isPresented: $isAddItemSheetPresented,
                        onAdd: { name, units, price in
                            viewModel.addItem(name: name, units: units, price: price)
                        }
                    )
                    .frame(width: 300, height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .zIndex(1)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

class InventoryViewModel: ObservableObject {
    @Published var items: [Inventory.Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchItems() {
        isLoading = true
        InventoryManager.shared.fetchInventoryItems { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let items):
                    self?.items = items
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func addItem(name: String, units: Int, price: Double) {
        let newItem = Inventory.Item(name: name, units: units, price: price)
        InventoryManager.shared.addInventoryItem(newItem) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.fetchItems()
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func updateItemUnits(itemId: String, newUnits: Int, newPrice: Double) {
        guard let item = items.first(where: { $0.id == itemId }) else { return }
        
        var updatedItem = item
        updatedItem.units = newUnits
        updatedItem.price = newPrice
        
        InventoryManager.shared.updateInventoryItem(updatedItem) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.fetchItems()
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
}

struct InventoryRow: View {
    let item: Inventory.Item
    var onUpdate: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Image(systemName: "cube.box.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    Text("Units: \(item.units)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(item.units <= item.minUnits ? .red : .secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    Text("Price: $\(String(format: "%.2f", item.price))")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onUpdate?()
                }
            }) {
                Text("Update")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .overlay(
                    LinearGradient(
                        colors: [.gray.opacity(0.05), .gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(radius: 4, y: 2)
        )
    }
}

struct UpdateSheet: View {
    let item: Inventory.Item
    let onClose: () -> Void
    let onUpdate: (Int, Double) -> Void
    @State private var tempUnits: Int
    @State private var tempPrice: String

    init(item: Inventory.Item, onClose: @escaping () -> Void, onUpdate: @escaping (Int, Double) -> Void) {
        self.item = item
        self.onClose = onClose
        self.onUpdate = onUpdate
        self._tempUnits = State(initialValue: item.units)
        self._tempPrice = State(initialValue: String(format: "%.2f", item.price))
    }

    var body: some View {
        VStack(spacing: 5) {
            Text("Update Item")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text(item.name)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 16) {
                HStack(spacing: 32) {
                    Button(action: {
                        tempUnits = max(0, tempUnits - 1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(tempUnits > 0 ? .blue : .gray)
                            .font(.system(size: 32))
                    }
                    .disabled(tempUnits <= 0)
                    
                    Text("\(tempUnits)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Button(action: {
                        tempUnits += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.system(size: 32))
                    }
                }
                
                TextField("Price", text: $tempPrice)
                    .font(.system(.subheadline, design: .rounded))
                    .keyboardType(.decimalPad)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 200)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.vertical, 16)
            
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        onClose()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    withAnimation(.spring()) {
                        if let price = Double(tempPrice) {
                            onUpdate(tempUnits, price)
                            onClose()
                        }
                    }
                }) {
                    Text("Update")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding()
        .interactiveDismissDisabled()
    }
}

struct AddItemSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, Int, Double) -> Void
    @State private var newItemName: String = ""
    @State private var newItemUnits: String = ""
    @State private var newItemPrice: String = ""

    var body: some View {
        VStack(spacing: 5) {
            Text("Add New Item")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 8) {
                TextField("Item Name", text: $newItemName)
                    .font(.system(.subheadline, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 270)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                TextField("Units", text: $newItemUnits)
                    .font(.system(.subheadline, design: .rounded))
                    .keyboardType(.numberPad)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 270)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                TextField("Price", text: $newItemPrice)
                    .font(.system(.subheadline, design: .rounded))
                    .keyboardType(.decimalPad)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 270)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.vertical, 8)

            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    if let units = Int(newItemUnits),
                       let price = Double(newItemPrice),
                       !newItemName.isEmpty,
                       units >= 0 {
                        onAdd(newItemName, units, price)
                        newItemName = ""
                        newItemUnits = ""
                        newItemPrice = ""
                        isPresented = false
                    }
                }) {
                    Text("Add Item")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isFormValid ? Color.blue : Color.blue.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
            }
            .padding(.horizontal, 16)
        }
        .padding()
        .interactiveDismissDisabled()
    }
    
    private var isFormValid: Bool {
        guard !newItemName.isEmpty,
              let units = Int(newItemUnits),
              let _ = Double(newItemPrice),
              units >= 0 else {
            return false
        }
        return true
    }
}

struct InventoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryManagementView()
    }
}
