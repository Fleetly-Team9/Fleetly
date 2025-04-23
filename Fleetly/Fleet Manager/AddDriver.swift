import SwiftUI

// MARK: - Model
struct Driver: Identifiable, Equatable {
    let id: UUID
    var name: String
    var aadhaarNumber: String
    var panCardNumber: String
    var age: String
    var licenseNumber: String
    var phoneNumber: String
    var licenseValidUpto: String
    var role: Role
}

// Enum for Role
enum Role: String, CaseIterable, Identifiable {
    case driver = "Driver"
    case maintenancePersonnel = "Maintenance Personnel"
    
    var id: String { self.rawValue }
}

// MARK: - ViewModel
class DriverManagerViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var searchText: String = ""
    @Published var sortAscending: Bool = true
    @Published var recentlyDeleted: Driver?

    var filteredDrivers: [Driver] {
        let filtered = drivers.filter {
            searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted {
            sortAscending ? $0.name < $1.name : $0.name > $1.name
        }
    }

    func delete(driver: Driver) {
        if let index = drivers.firstIndex(of: driver) {
            recentlyDeleted = drivers.remove(at: index)
        }
    }

    func undoDelete() {
        if let driver = recentlyDeleted {
            drivers.append(driver)
            recentlyDeleted = nil
        }
    }

    func add(driver: Driver) {
        drivers.append(driver)
    }

    func update(driver: Driver) {
        if let index = drivers.firstIndex(where: { $0.id == driver.id }) {
            drivers[index] = driver
        }
    }
}
// MARK: - Placeholder View
struct DriverPlaceholderView: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclam")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 10)

            Text("No Personnel Added")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Tap the button below to start adding drivers or maintenance personnel.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onCreate) {
                Text("Add Staff")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 10)
                .padding()
        )
    }
}


// MARK: - Main View
struct DriverManagerView: View {
    @StateObject private var viewModel = DriverManagerViewModel()
    @State private var showingAddDriver = false
    @State private var editingDriver: Driver? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.filteredDrivers.isEmpty {
                    DriverPlaceholderView {
                        showingAddDriver = true
                    }
                } else {
                    List {
                        ForEach(viewModel.filteredDrivers) { driver in
                            DriverCard(driver: driver) {
                                withAnimation {
                                    viewModel.delete(driver: driver)
                                }
                            }
                            .onTapGesture {
                                editingDriver = driver
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.delete(driver: driver)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Staff Details")
            .toolbar {
                if !viewModel.filteredDrivers.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddDriver = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddDriver) {
                DriverFormView(viewModel: viewModel, editingDriver: nil)
            }
            .sheet(item: $editingDriver) { driver in
                DriverFormView(viewModel: viewModel, editingDriver: driver)
            }
            .overlay(alignment: .bottom) {
                if let _ = viewModel.recentlyDeleted {
                    UndoToast1 {
                        viewModel.undoDelete()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.recentlyDeleted)
                }
            }
        }
    }
}

// MARK: - Card View
struct DriverCard: View {
    var driver: Driver
    var onDelete: () -> Void

    @State private var offsetX: CGFloat = 0
    @GestureState private var isDragging = false
    @State private var licenseStatus: String = ""

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background delete button (on the right)
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .padding(.trailing)
                .opacity(offsetX < -100 ? 1 : 0)
            }

            // Foreground card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 26))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.name)
                            .font(.title3.bold())
                        Text("Role: \(driver.role.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("License Status: \(licenseStatus)")
                            .font(.subheadline)
                            .foregroundColor(licenseStatus == "Expired" ? .red : .green)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .offset(x: offsetX)
            .padding(.vertical, 4)
            .onAppear {
                updateLicenseStatus()
            }
            .gesture(
                DragGesture()
                    .updating($isDragging) { value, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        offsetX = min(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width < -100 {
                            withAnimation {
                                onDelete()
                            }
                        } else {
                            withAnimation {
                                offsetX = 0
                            }
                        }
                    }
            )
        }
        .animation(.spring(), value: offsetX)
    }

    private func updateLicenseStatus() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let validUptoDate = dateFormatter.date(from: driver.licenseValidUpto),
           let currentDate = dateFormatter.date(from: dateFormatter.string(from: Date())) {
            licenseStatus = validUptoDate >= currentDate ? "Active" : "Expired"
        } else {
            licenseStatus = "Unknown"
        }
    }
}

// MARK: - Form View
struct DriverFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DriverManagerViewModel

    @State private var name = ""
    @State private var aadhaarNumber = ""
    @State private var panCardNumber = ""
    @State private var age = ""
    @State private var licenseNumber = ""
    @State private var phoneNumber = ""
    @State private var licenseValidUpto = Date()
    @State private var role: Role = .driver

    var editingDriver: Driver?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User Details")) {
                    TextField("Name", text: $name)
                    TextField("Aadhaar Number", text: $aadhaarNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: aadhaarNumber) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 12 {
                                aadhaarNumber = String(digits.prefix(12)).formatAadhaar()
                            } else {
                                aadhaarNumber = digits.formatAadhaar()
                            }
                        }
                    TextField("PAN Card Number", text: $panCardNumber)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: panCardNumber) { newValue in
                            let formatted = formatPAN(newValue)
                            panCardNumber = formatted
                        }
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("License Number", text: $licenseNumber)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: phoneNumber) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 10 {
                                phoneNumber = String(digits.prefix(10))
                            } else {
                                phoneNumber = digits
                            }
                        }
                    DatePicker("License Valid Upto", selection: $licenseValidUpto, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                    Picker("Role", selection: $role) {
                        ForEach(Role.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle(editingDriver == nil ? "Add Driver" : "Edit Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let licenseValidUptoStr = dateFormatter.string(from: licenseValidUpto)
                        let driver = Driver(
                            id: editingDriver?.id ?? UUID(),
                            name: name,
                            aadhaarNumber: aadhaarNumber,
                            panCardNumber: panCardNumber,
                            age: age,
                            licenseNumber: licenseNumber,
                            phoneNumber: phoneNumber,
                            licenseValidUpto: licenseValidUptoStr,
                            role: role
                        )
                        if editingDriver == nil {
                            viewModel.add(driver: driver)
                        } else {
                            viewModel.update(driver: driver)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || aadhaarNumber.isEmpty || panCardNumber.isEmpty || age.isEmpty || licenseNumber.isEmpty || phoneNumber.isEmpty || phoneNumber.count != 10 || aadhaarNumber.replacingOccurrences(of: "-", with: "").count != 12 || panCardNumber.count != 10)
                }
            }
            .onAppear {
                if let driver = editingDriver {
                    name = driver.name
                    aadhaarNumber = driver.aadhaarNumber.formatAadhaar()
                    panCardNumber = driver.panCardNumber
                    age = driver.age
                    licenseNumber = driver.licenseNumber
                    phoneNumber = driver.phoneNumber
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let date = dateFormatter.date(from: driver.licenseValidUpto) {
                        licenseValidUpto = date
                    }
                    role = driver.role
                }
            }
        }
    }

    // Helper function to format Aadhaar number
    private func formatAadhaar() -> String {
        let digits = aadhaarNumber.replacingOccurrences(of: "-", with: "").filter { $0.isNumber }
        guard digits.count <= 12 else { return String(digits.prefix(12)).formatAadhaar() }
        var formatted = digits
        if formatted.count > 4 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 4))
        }
        if formatted.count > 9 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 9))
        }
        return formatted
    }

    // Helper function to format PAN number
    private func formatPAN(_ value: String) -> String {
        let allowedChars = value.uppercased().filter { $0.isLetter || $0.isNumber }
        guard allowedChars.count <= 10 else { return String(allowedChars.prefix(10)) }
        
        var formatted = allowedChars
        if formatted.count > 5 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 5))
        }
        if formatted.count > 3 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 3))
        }
        
        
        let components = formatted.split(separator: "-")
        var result = ""
        if components.count >= 4 {
            let ss = components[0].prefix(2)
            let rr = components[1].prefix(2)
            let yyyy = components[2].prefix(4)
            let nnnnnn = components[3].prefix(6)
            result = "\(ss)-\(rr)-\(yyyy)-\(nnnnnn)"
        } else {
            result = formatted
        }
        
        return String(result.prefix(12))
    }
}

// Extension to format Aadhaar number
extension String {
    func formatAadhaar() -> String {
        let digits = self.replacingOccurrences(of: "-", with: "").filter { $0.isNumber }
        guard digits.count <= 12 else { return String(digits.prefix(12)).formatAadhaar() }
        var formatted = digits
        if formatted.count > 4 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 4))
        }
        if formatted.count > 9 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 9))
        }
        return formatted
    }
}

// MARK: - Undo Toast


struct UndoToast1   : View {
    var undoAction: () -> Void
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack {
                Text("Personnel deleted")
                Spacer()
                Button("Undo", action: undoAction)
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}

#Preview {
    DriverManagerView()
}
