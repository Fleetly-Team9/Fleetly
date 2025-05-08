import SwiftUI

struct MaintenanceDetailView: View {
    @Binding var order: WorkOrder
    @State private var newPart = ""
    @State private var laborCost: String = ""
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var colorManager = ColorManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Maintenance Details - #\(order.id)")
                    .font(.system(.title2, design: .default).weight(.bold))
                    .foregroundColor(Color(hex: "444444"))
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Vehicle: \(order.vehicleNumber)")
                    Text("Issue: \(order.issue)")
                    Text("Status: \(order.status)")
                    Text("Delivery: \(order.expectedDelivery ?? "N/A")")
                }
                .padding()
                .background(Color(hex: "D1D5DB"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Parts Used")
                        .font(.headline)
                    List {
                        ForEach(order.parts, id: \.self) { part in
                            Text(part)
                        }
                        HStack {
                            TextField("Add Part", text: $newPart)
                            Button("Add") {
                                if !newPart.isEmpty {
                                    order.parts.append(newPart)
                                    newPart = ""
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(colorManager.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    Text("Labor Cost: \(laborCost.isEmpty ? "N/A" : "$\(laborCost)")")
                    TextField("Enter Labor Cost", text: $laborCost)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(hex: "E6E6E6"))
                        .cornerRadius(8)
                        .onChange(of: laborCost) { newValue in
                            if let cost = Double(newValue) {
                                order.laborCost = cost
                            } else {
                                order.laborCost = nil
                            }
                        }
                }
                .padding()

                Button("Generate Report") {
                    generateReport()
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .background(colorManager.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(12)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateReport() {
        let report = """
        Maintenance Report - Work Order #\(order.id)
        Vehicle: \(order.vehicleNumber)
        Issue: \(order.issue)
        Status: \(order.status)
        Delivery: \(order.expectedDelivery ?? "N/A")
        Parts Used: \(order.parts.joined(separator: ", "))
        Labor Cost: \(laborCost.isEmpty ? "N/A" : "$\(laborCost)")
        """
        print("Report sent to Fleet Manager and Driver: \(report)")
    }
}
