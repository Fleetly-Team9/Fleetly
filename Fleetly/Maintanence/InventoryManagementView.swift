import SwiftUI

struct InventoryManagementView: View {
    @Binding var items: [InventoryItem]
    @State private var selectedItem: InventoryItem?
    @State private var isSheetPresented = false
    @State private var showRowAnimation = false
    @State private var isAddItemSheetPresented = false

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
                        if items.isEmpty {
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
                            ForEach($items) { $item in
                                InventoryRow(
                                    item: $item,
                                    onUpdate: {
                                        selectedItem = $item.wrappedValue
                                        isSheetPresented = true
                                    }
                                )
                                .padding(.horizontal, 16)
                                .opacity(showRowAnimation ? 1 : 0)
                                .offset(y: showRowAnimation ? 0 : 20)
                                .animation(
                                    .easeOut(duration: 0.5).delay(Double(items.firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1),
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
                }

                // Update Sheet Overlay
                if isSheetPresented, let selectedItem = selectedItem, let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
                    Color.black.opacity(0.25).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isSheetPresented = false
                            }
                        }

                    UpdateSheet(item: $items[index]) {
                        withAnimation {
                            isSheetPresented = false
                        }
                    }
                    .frame(width: 300, height: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                }

                // Add Item Sheet Overlay
                if isAddItemSheetPresented {
                    Color.black.opacity(0.25).ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                isAddItemSheetPresented = false
                            }
                        }

                    AddItemSheet(items: $items)
                        .frame(width: 300, height: 300)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                        )
                }
            }
        }
    }
}

struct InventoryRow: View {
    @Binding var item: InventoryItem
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
                        .foregroundStyle(item.units <= 5 ? .red : .secondary)
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
    @Binding var item: InventoryItem
    var onClose: () -> Void
    @State private var minusTapped = false
    @State private var plusTapped = false
    @State private var cancelTapped = false
    @State private var updateTapped = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Update Units")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            // Item Info
            Text(item.name)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            // Unit Adjustment
            HStack(spacing: 32) {
                Button(action: {
                    if item.units > 0 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            minusTapped.toggle()
                            item.units -= 1
                        }
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(item.units > 0 ? .blue : .gray)
                        .font(.system(size: 32))
                        .scaleEffect(minusTapped ? 1.1 : 1.0)
                }
                .disabled(item.units <= 0)

                Text("\(item.units)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        plusTapped.toggle()
                        item.units += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 32))
                        .scaleEffect(plusTapped ? 1.1 : 1.0)
                }
            }
            .padding(.vertical, 16)

            // Actions
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        cancelTapped.toggle()
                        onClose()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .scaleEffect(cancelTapped ? 1.05 : 1.0)

                Button(action: {
                    withAnimation(.spring()) {
                        updateTapped.toggle()
                        onClose()
                    }
                }) {
                    Text("Update")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .scaleEffect(updateTapped ? 1.05 : 1.0)
            }
            .padding(.horizontal, 16)
        }
        .padding()
    }
}

struct AddItemSheet: View {
    @Binding var items: [InventoryItem]
    @Environment(\.dismiss) var dismiss
    @State private var newItemName: String = ""
    @State private var newItemUnits: String = ""
    @State private var cancelTapped = false
    @State private var addTapped = false

    var body: some View {
        VStack(spacing: 20) {
            // Header with Drag Indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            Text("Add New Item")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            // Form
            VStack(spacing: 16) {
                TextField("Item Name", text: $newItemName)
                    .font(.system(.body, design: .rounded))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                TextField("Units", text: $newItemUnits)
                    .font(.system(.body, design: .rounded))
                    .keyboardType(.numberPad)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }

            // Actions
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        cancelTapped.toggle()
                        dismiss()
                    }
                }) {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .scaleEffect(cancelTapped ? 1.05 : 1.0)

                Button(action: {
                    if let units = Int(newItemUnits), !newItemName.isEmpty {
                        let newItem = InventoryItem(
                            id: (items.map { $0.id }.max() ?? 0) + 1,
                            name: newItemName,
                            units: units
                        )
                        withAnimation {
                            items.append(newItem)
                            addTapped.toggle()
                            dismiss()
                        }
                    }
                }) {
                    Text("Add Item")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(newItemName.isEmpty || newItemUnits.isEmpty ? Color.gray : .blue)
                        )
                }
                .scaleEffect(addTapped ? 1.05 : 1.0)
                .disabled(newItemName.isEmpty || newItemUnits.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.top, 8)
    }
}

struct InventoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryManagementView(
            items: .constant([
                InventoryItem(id: 1, name: "Brake Pads", units: 12),
                InventoryItem(id: 2, name: "Oil Filter", units: 10)
            ])
        )
    }
}
