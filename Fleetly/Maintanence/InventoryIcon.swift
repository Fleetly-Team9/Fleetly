import SwiftUI

// Color Extension
extension Color {
    static let darkGray = Color(hex: "444444")
    static let lightGray = Color(hex: "F0F2F5")
    static let highlightYellow = Color(hex: "FFDE8F")
    static let backgroundGray = Color(hex: "F9FAFB")
    static let todayGreen = Color(hex: "34C759")
    static let customBlue = Color(hex: "007AFF")
    static let cardBackground = Color.white
    static let gradientStart = Color(hex: "4A90E2")
    static let gradientEnd = Color(hex: "50E3C2")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// Reusable Components
struct InventoryIcon: View {
    let item: InventoryItem
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(hex: "EFF0F0"))
                    .frame(width: 60, height: 60)
                Image(systemName: itemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(Color(hex: "444444"))
            }
            Text(item.name)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(Color(hex: "444444"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("\(item.units) units")
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(Color(hex: "444444").opacity(0.6))
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
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Color(hex: "444444"))
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: "F9FAFB")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
}

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(message.sender)
                        .font(.system(.headline, design: .rounded).weight(.medium))
                    Spacer()
                    Text(message.time)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Text(message.content)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InventoryRow: View {
    let item: InventoryItem
    let onUpdate: () -> Void
    @State private var isTapped = false
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(hex: "EFF0F0"))
                    .frame(width: 40, height: 40)
                Image(systemName: itemIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Color(hex: "444444"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(.headline, design: .rounded).weight(.medium))
                    .foregroundColor(Color(hex: "444444"))
                Text("\(item.units) units left")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Color(hex: "444444").opacity(0.6))
            }
            .padding(.leading, 5)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isTapped.toggle()
                    onUpdate()
                }
            }) {
                Text("Update")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.blue)
            }
            .scaleEffect(isTapped ? 1.05 : 1.0)
            .accessibilityLabel("Update \(item.name) units")
        }
        .padding(.horizontal)
        .frame(width: 351, height: 58)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(hex: "F9FAFB")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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

