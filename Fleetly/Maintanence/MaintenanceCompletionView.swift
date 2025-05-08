import SwiftUI
import FirebaseFirestore

struct MaintenanceCompletionView: View {
    let task: MaintenanceTask
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MaintenanceCompletionViewModel()
    @State private var selectedParts: [Inventory.Item] = []
    @State private var partQuantities: [String: Int] = [:]
    @State private var laborCost: String = ""
    @State private var otherCosts: [(description: String, amount: String)] = [("", "")]
    @State private var showingPartSelection = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @StateObject private var colorManager = ColorManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Parts Used") {
                    ForEach(selectedParts) { part in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(part.name)
                                    .font(.headline)
                                Text("Unit Price: $\(String(format: "%.2f", part.price))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button(action: {
                                    if let currentQty = partQuantities[part.id], currentQty > 1 {
                                        partQuantities[part.id] = currentQty - 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(colorManager.accentColor)
                                }
                                
                                Text("\(partQuantities[part.id] ?? 1)")
                                    .frame(minWidth: 30)
                                
                                Button(action: {
                                    partQuantities[part.id] = (partQuantities[part.id] ?? 1) + 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(colorManager.accentColor)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        showingPartSelection = true
                    }) {
                        Label("Add Part", systemImage: "plus.circle.fill")
                    }
                }
                
                Section("Labor Cost") {
                    TextField("Enter labor cost", text: $laborCost)
                        .keyboardType(.decimalPad)
                }
                
                Section("Other Costs") {
                    ForEach(otherCosts.indices, id: \.self) { index in
                        HStack {
                            TextField("Description", text: $otherCosts[index].description)
                            TextField("Amount", text: $otherCosts[index].amount)
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                        }
                    }
                    
                    Button(action: {
                        otherCosts.append(("", ""))
                    }) {
                        Label("Add Cost", systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    HStack {
                        Text("Total Cost")
                            .font(.headline)
                        Spacer()
                        Text("$\(String(format: "%.2f", totalCost))")
                            .font(.headline)
                            .foregroundColor(colorManager.primaryColor)
                    }
                }
            }
            .navigationTitle("Complete Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeMaintenance()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingPartSelection) {
                PartSelectionView(selectedParts: $selectedParts)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                viewModel.fetchInventoryItems()
            }
            .dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
        }
    }
    
    private var totalCost: Double {
        var total = 0.0
        
        // Parts cost
        for part in selectedParts {
            let quantity = Double(partQuantities[part.id] ?? 1)
            total += part.price * quantity
        }
        
        // Labor cost
        if let labor = Double(laborCost.trimmingCharacters(in: .whitespacesAndNewlines)) {
            total += labor
        }
        
        // Other costs
        for cost in otherCosts {
            if !cost.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let amount = Double(cost.amount.trimmingCharacters(in: .whitespacesAndNewlines)) {
                total += amount
            }
        }
        
        return total
    }
    
    private var isFormValid: Bool {
        guard !selectedParts.isEmpty,
              !laborCost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let labor = Double(laborCost.trimmingCharacters(in: .whitespacesAndNewlines)),
              labor >= 0 else {
            return false
        }
        
        // Check if all other costs have valid amounts
        for cost in otherCosts {
            if !cost.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                guard let amount = Double(cost.amount.trimmingCharacters(in: .whitespacesAndNewlines)),
                      amount > 0 else {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func completeMaintenance() {
        let partsUsed = selectedParts.map { part in
            Inventory.MaintenanceCost.PartUsage(
                partId: part.id,
                partName: part.name,
                quantity: partQuantities[part.id] ?? 1,
                unitPrice: part.price
            )
        }
        
        // Filter out empty other costs and ensure all have valid amounts
        let otherCostsList = otherCosts.compactMap { cost -> Inventory.MaintenanceCost.OtherCost? in
            // Only include costs that have both description and amount
            guard !cost.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let amount = Double(cost.amount.trimmingCharacters(in: .whitespacesAndNewlines)),
                  amount > 0 else {
                return nil
            }
            return Inventory.MaintenanceCost.OtherCost(
                description: cost.description.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount
            )
        }
        
        let maintenanceCost = Inventory.MaintenanceCost(
            id: UUID().uuidString,
            taskId: task.id,
            partsUsed: partsUsed,
            laborCost: Double(laborCost.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
            otherCosts: otherCostsList,
            totalCost: totalCost,
            timestamp: Date()
        )
        
        viewModel.completeMaintenance(task: task, cost: maintenanceCost) { success in
            if success {
                dismiss()
            } else {
                errorMessage = viewModel.errorMessage ?? "Failed to complete maintenance"
                showingError = true
            }
        }
    }
}

struct PartSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedParts: [Inventory.Item]
    @StateObject private var viewModel = MaintenanceCompletionViewModel()
    @StateObject private var colorManager = ColorManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.inventoryItems) { item in
                    Button(action: {
                        if !selectedParts.contains(where: { $0.id == item.id }) {
                            selectedParts.append(item)
                        }
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Available: \(item.units) units")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", item.price))")
                                .font(.subheadline)
                                .foregroundColor(colorManager.primaryColor)
                        }
                    }
                    .disabled(item.units <= 0)
                }
            }
            .navigationTitle("Select Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.fetchInventoryItems()
            }
        }
    }
}

class MaintenanceCompletionViewModel: ObservableObject {
    @Published var inventoryItems: [Inventory.Item] = []
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    
    func fetchInventoryItems() {
        InventoryManager.shared.fetchInventoryItems { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self?.inventoryItems = items
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func completeMaintenance(task: MaintenanceTask, cost: Inventory.MaintenanceCost, completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        
        // Update task status
        let taskRef = db.collection("maintenance_tasks").document(task.id)
        batch.updateData([
            "status": MaintenanceTask.TaskStatus.completed.rawValue,
            "completedAt": FieldValue.serverTimestamp()
        ], forDocument: taskRef)
        
        // Save maintenance cost in the costs subcollection
        let costRef = db.collection("maintenance_tasks").document(task.id).collection("costs").document(cost.id)
        do {
            try batch.setData(from: cost, forDocument: costRef)
        } catch {
            self.errorMessage = "Error encoding maintenance cost: \(error.localizedDescription)"
            completion(false)
            return
        }
        
        // Update inventory quantities
        for partUsage in cost.partsUsed {
            let partRef = db.collection("inventory").document(partUsage.partId)
            batch.updateData([
                "units": FieldValue.increment(-Int64(partUsage.quantity))
            ], forDocument: partRef)
        }
        
        // Commit the batch
        batch.commit { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error completing maintenance: \(error.localizedDescription)"
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
} 
