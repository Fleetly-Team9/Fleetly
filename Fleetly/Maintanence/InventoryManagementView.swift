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
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var colorManager = ColorManager.shared
    
    var filteredItems: [Inventory.Item] {
        let items = viewModel.items
        let searchFiltered = searchText.isEmpty ? items : items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return searchFiltered.sorted { item1, item2 in
            if item1.units <= item1.minUnits && item2.units > item2.minUnits {
                return true
            } else if item1.units > item1.minUnits && item2.units <= item2.minUnits {
                return false
            } else {
                return item1.name < item2.name
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search inventory...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(.secondarySystemBackground),
                                            Color(.secondarySystemBackground).opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Stats Overview
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Total Items",
                                value: "\(viewModel.items.count)",
                                icon: "cube.box.fill",
                                color: colorManager.primaryColor
                            )
                            
                            StatCard(
                                title: "Low Stock",
                                value: "\(viewModel.items.filter { $0.units <= $0.minUnits }.count)",
                                icon: "exclamationmark.triangle.fill",
                                color: colorManager.accentColor
                            )
                        }
                        .padding(.horizontal)
                        
                        // Low Stock Alert
                        if filteredItems.contains(where: { $0.units <= $0.minUnits }) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(colorManager.accentColor)
                                Text("Items need attention")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(colorManager.accentColor)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Inventory List
                        VStack(spacing: 12) {
                            if filteredItems.isEmpty {
                                EmptyStateView(
                                    icon: "cube.box",
                                    title: "No Items Found",
                                    message: searchText.isEmpty ? "Add items to your inventory" : "Try a different search term"
                                )
                            } else {
                                ForEach(filteredItems) { item in
                                    InventoryRow(
                                        item: item,
                                        onUpdate: {
                                            selectedItemId = item.id
                                            isSheetPresented = true
                                        }
                                    )
                                    .opacity(showRowAnimation ? 1 : 0)
                                    .offset(y: showRowAnimation ? 0 : 20)
                                    .animation(
                                        .easeOut(duration: 0.5).delay(Double(viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1),
                                        value: showRowAnimation
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Inventory")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddItemSheetPresented = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(colorManager.primaryColor)
                                .font(.system(size: 22))
                        }
                    }
                }
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
                    .frame(width: 300, height: 250)
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Title Row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Value
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct InventoryRow: View {
    let item: Inventory.Item
    var onUpdate: (() -> Void)?
    @StateObject private var colorManager = ColorManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Item Details
            VStack(alignment: .leading, spacing: 6) {
                // Name and Status
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if item.units <= item.minUnits {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colorManager.accentColor)
                            .imageScale(.small)
                    }
                }
                
                // Units and Price
                HStack(spacing: 16) {
                    // Units
                    HStack(spacing: 4) {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(item.units <= item.minUnits ? colorManager.accentColor : .secondary)
                            .imageScale(.small)
                        Text("\(item.units) units")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(item.units <= item.minUnits ? colorManager.accentColor : .secondary)
                    }
                    
                    // Price
                    Text("₹\(String(format: "%.2f", item.price))")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Update Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onUpdate?()
                }
            }) {
                Text("Update")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [colorManager.primaryColor.opacity(0.15), colorManager.primaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(colorManager.primaryColor)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.secondarySystemBackground),
                            Color(.secondarySystemBackground).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    item.units <= item.minUnits ? colorManager.accentColor.opacity(0.3) : colorManager.primaryColor.opacity(0.3),
                                    item.units <= item.minUnits ? colorManager.accentColor.opacity(0.1) : colorManager.primaryColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
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

struct UpdateSheet: View {
    let item: Inventory.Item
    let onClose: () -> Void
    let onUpdate: (Int, Double) -> Void
    @State private var tempUnits: Int
    @State private var tempPrice: String
    @StateObject private var colorManager = ColorManager.shared

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
                            .foregroundStyle(tempUnits > 0 ? colorManager.primaryColor : .gray)
                            .font(.system(size: 32))
                    }
                    .disabled(tempUnits <= 0)
                    
                    Text("\(tempUnits)")
                        .font(.system(size: 32))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Button(action: {
                        tempUnits += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(colorManager.primaryColor)
                            .font(.system(size: 32))
                    }
                }
                
                TextField("Price", text: $tempPrice)
                    .font(.system(.subheadline, design: .rounded))
                    .keyboardType(.decimalPad)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: 230)
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
                        .foregroundColor(colorManager.primaryColor)
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
                        .foregroundColor(colorManager.primaryColor)
                        .frame(maxWidth: 120)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
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
    @StateObject private var colorManager = ColorManager.shared

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
                        .foregroundColor(colorManager.primaryColor)
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
                        .background(isFormValid ? colorManager.primaryColor : colorManager.primaryColor.opacity(0.5))
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
