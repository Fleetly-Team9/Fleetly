import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var inventoryItems = [
        InventoryItem(id: 1, name: "Brake Pads", units: 12),
        InventoryItem(id: 2, name: "Oil Filter", units: 0),
        InventoryItem(id: 3, name: "Air Filter", units: 17),
        InventoryItem(id: 4, name: "Spark Plug", units: 20),
        InventoryItem(id: 5, name: "Battery", units: 6),
        InventoryItem(id: 6, name: "Clutch Plate", units: 9)
    ]

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            InventoryManagementView(items: $inventoryItems)
                .tabItem {
                    Label("Inventory", systemImage: "cart.fill")
                }
                .tag(1)

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
        }
        .accentColor(.blue) // Sets the selected tab item color to blue to match the screenshot
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
