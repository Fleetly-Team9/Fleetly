import SwiftUI


// Reusable Components
struct InventoryIcon: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                Image(systemName: itemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.primary)
            }
            Text(item.name)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("\(item.units) units")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(width: 80, height: 100)
    }
    
    private var itemIcon: String {
        switch item.name {
        case "Brake Pads":
            return "car.fill"
        case "Oil Filter":
            return "drop.fill"
        case "Air Filter":
            return "wind"
        case "Spark Plug":
            return "bolt.fill"
        case "Battery":
            return "battery.25"
        case "Clutch Plate":
            return "gearshape"
        default:
            return "gear"
        }
    }
}

struct AlertItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .frame(width: 24, height: 24)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .overlay(.ultraThinMaterial)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}
