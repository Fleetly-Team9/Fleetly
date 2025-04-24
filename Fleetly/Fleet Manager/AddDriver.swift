import SwiftUI

// MARK: - Model
struct Driver: Identifiable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var aadhaarNumber: String
    var age: String
    var contactNumber: String
    var role: Role
    var gender: Gender? // Optional, only for Driver
    var email: String? // Optional, only for Driver
    var licenseNumber: String? // Optional, only for Driver
    var licenseValidUpto: String? // Optional, only for Driver
}

// Enum for Role
enum Role: String, CaseIterable, Identifiable {
    case driver = "Driver"
    case maintenancePersonnel = "Maintenance Personnel"
    
    var id: String { self.rawValue }
}

// Enum for Gender
enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    
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
            searchText.isEmpty || "\($0.firstName) \($0.lastName)".lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted {
            sortAscending ? $0.firstName < $1.firstName : $0.firstName > $1.firstName
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
                        Text("\(driver.firstName) \(driver.lastName)")
                            .font(.title3.bold())
                        Text("Role: \(driver.role.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if driver.role == .driver, let licenseValidUpto = driver.licenseValidUpto {
                            Text("License Status: \(licenseStatus)")
                                .font(.subheadline)
                                .foregroundColor(licenseStatus == "Expired" ? .red : .green)
                        }
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
        if driver.role == .driver, let validUpto = driver.licenseValidUpto {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let validUptoDate = dateFormatter.date(from: validUpto),
               let currentDate = dateFormatter.date(from: dateFormatter.string(from: Date())) {
                licenseStatus = validUptoDate >= currentDate ? "Active" : "Expired"
            } else {
                licenseStatus = "Unknown"
            }
        } else {
            licenseStatus = "N/A"
        }
    }
}

// MARK: - Form View
struct DriverFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DriverManagerViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var aadhaarNumber = ""
    @State private var age = ""
    @State private var contactNumber = ""
    @State private var gender: Gender = .male
    @State private var email = ""
    @State private var licenseNumber = ""
    @State private var licenseValidUpto = Date()
    @State private var role: Role = .driver

    var editingDriver: Driver?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personnel Details")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
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
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Contact Number", text: $contactNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: contactNumber) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 10 {
                                contactNumber = String(digits.prefix(10))
                            } else {
                                contactNumber = digits
                            }
                        }
                    Picker("Role", selection: $role) {
                        ForEach(Role.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if role == .driver {
                    Section(header: Text("Driver Details")) {
                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                        .pickerStyle(.menu)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                        TextField("License Number", text: $licenseNumber)
                        DatePicker("License Valid Upto", selection: $licenseValidUpto, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    }
                }
            }
            .navigationTitle(editingDriver == nil ? "Add Personnel" : "Edit Personnel")
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
                        let licenseValidUptoStr = role == .driver ? dateFormatter.string(from: licenseValidUpto) : nil
                        let driver = Driver(
                            id: editingDriver?.id ?? UUID(),
                            firstName: firstName,
                            lastName: lastName,
                            aadhaarNumber: aadhaarNumber,
                            age: age,
                            contactNumber: contactNumber,
                            role: role,
                            gender: role == .driver ? gender : nil,
                            email: role == .driver ? email : nil,
                            licenseNumber: role == .driver ? licenseNumber : nil,
                            licenseValidUpto: licenseValidUptoStr
                        )
                        if editingDriver == nil {
                            viewModel.add(driver: driver)
                        } else {
                            viewModel.update(driver: driver)
                        }
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if let driver = editingDriver {
                    firstName = driver.firstName
                    lastName = driver.lastName
                    aadhaarNumber = driver.aadhaarNumber.formatAadhaar()
                    age = driver.age
                    contactNumber = driver.contactNumber
                    role = driver.role
                    gender = driver.gender ?? .male
                    email = driver.email ?? ""
                    licenseNumber = driver.licenseNumber ?? ""
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let date = driver.licenseValidUpto.flatMap({ dateFormatter.date(from: $0) }) {
                        licenseValidUpto = date
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        let commonValid = !firstName.isEmpty &&
                          !lastName.isEmpty &&
                          aadhaarNumber.replacingOccurrences(of: "-", with: "").count == 12 &&
                          !age.isEmpty &&
                          contactNumber.count == 10
        
        if role == .driver {
            return commonValid &&
                   !email.isEmpty &&
                   !licenseNumber.isEmpty
        } else {
            return commonValid
        }
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
struct UndoToast1: View {
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
