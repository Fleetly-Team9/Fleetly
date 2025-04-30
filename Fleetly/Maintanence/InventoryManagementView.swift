import SwiftUI

struct InventoryManagementView: View {
    @Binding var items: [InventoryItem]
    @State private var selectedItemIndex: Int?
    @State private var isSheetPresented = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Inventory Management")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(Color(hex: "444444"))
                    .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(items.indices, id: \.self) { index in
                            InventoryRow(item: items[index], onUpdate: {
                                selectedItemIndex = index
                                isSheetPresented = true
                            })
                            .background(Color(hex: "D1D5DB"))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            
            if isSheetPresented, let index = selectedItemIndex {
                Color.black.opacity(0.25).ignoresSafeArea()
                    .onTapGesture {
                        isSheetPresented = false
                    }
                
                UpdateSheet(item: $items[index]) {
                    isSheetPresented = false
                }
                .frame(width: 250, height: 200)
                .background(Color(hex: "D1D5DB"))
                .cornerRadius(20)
                .shadow(radius: 10)
            }
        }
        .navigationTitle("Inventory")
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
        VStack(spacing: 10) {
            Text("Update Units")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(Color(hex: "444444"))
            Text(item.name)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color(hex: "444444").opacity(0.6))
            
            HStack(spacing: 30) {
                Button {
                    if item.units > 0 {
                        withAnimation(.spring()) {
                            minusTapped.toggle()
                            item.units -= 1
                        }
                    }
                } label: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "minus").foregroundColor(Color(hex: "444444")))
                }
                .scaleEffect(minusTapped ? 1.1 : 1.0)
                .accessibilityLabel("Decrease units")
                
                Text("\(item.units)")
                    .font(.system(.title2, design: .rounded).weight(.medium))
                    .foregroundColor(Color(hex: "444444"))
                
                Button {
                    withAnimation(.spring()) {
                        plusTapped.toggle()
                        item.units += 1
                    }
                } label: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "plus").foregroundColor(.blue))
                }
                .scaleEffect(plusTapped ? 1.1 : 1.0)
                .accessibilityLabel("Increase units")
            }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    withAnimation(.spring()) {
                        cancelTapped.toggle()
                        onClose()
                    }
                }
                .frame(width: 100, height: 36)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
                .scaleEffect(cancelTapped ? 1.05 : 1.0)
                .accessibilityLabel("Cancel update")
                
                Button("Update") {
                    withAnimation(.spring()) {
                        updateTapped.toggle()
                        onClose()
                    }
                }
                .frame(width: 100, height: 36)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .scaleEffect(updateTapped ? 1.05 : 1.0)
                .accessibilityLabel("Confirm update")
            }
            .padding(.top, 10)
        }
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
