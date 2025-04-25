import SwiftUI
import Firebase
import FirebaseFirestore

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
    var documentId: String? //For Firebase document ID
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
    
    var id: String { self.rawValue }
}

// MARK: - ViewModel

class DriverManagerViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var searchText: String = ""
    @Published var sortAscending: Bool = true
    @Published var recentlyDeleted: Driver?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        fetchDrivers()
    }
    
    var filteredDrivers: [Driver] {
        let filtered = drivers.filter {
            searchText.isEmpty || "\($0.firstName) \($0.lastName)".lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted {
            sortAscending ? $0.firstName < $1.firstName : $0.firstName > $1.firstName
        }
    }
    
    func fetchDrivers() {
        isLoading = true
        print("Fetching drivers from Firestore...")

        db.collection("Drivers").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            defer { self.isLoading = false }

            if let error = error {
                self.errorMessage = "Error fetching drivers: \(error.localizedDescription)"
                print(self.errorMessage!)
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No documents found.")
                return
            }

            print("Number of drivers fetched: \(documents.count)")

            var loadedDrivers: [Driver] = []

            for document in documents {
                let data = document.data()

                guard
                    let firstName = data["firstName"] as? String,
                    let lastName = data["lastName"] as? String,
                    let aadhaarNumber = data["aadhaarNumber"] as? String,
                    let age = data["age"] as? String,
                    let contactNumber = data["contactNumber"] as? String,
                    let roleString = data["role"] as? String,
                    let role = Role(rawValue: roleString)
                else {
                    print("Skipping document due to missing fields: \(document.documentID)")
                    continue
                }
                
                // Parse optional fields
                let gender = (data["gender"] as? String).flatMap { Gender(rawValue: $0) }
                let email = data["email"] as? String
                let licenseNumber = data["licenseNumber"] as? String
                let licenseValidUpto = data["licenseValidUpto"] as? String

                let driver = Driver(
                    id: UUID(),
                    firstName: firstName,
                    lastName: lastName,
                    aadhaarNumber: aadhaarNumber,
                    age: age,
                    contactNumber: contactNumber,
                    role: role,
                    gender: gender,
                    email: email,
                    licenseNumber: licenseNumber,
                    licenseValidUpto: licenseValidUpto,
                    documentId: document.documentID
                )

                loadedDrivers.append(driver)
                print("Loaded driver with Aadhaar: \(aadhaarNumber), documentId: \(document.documentID)")
            }

            DispatchQueue.main.async {
                self.drivers = loadedDrivers
                print("Drivers successfully loaded: \(self.drivers.count)")
            }
        }
    }

    private func saveDriverToFirestore(driver: Driver, documentId: String, completion: @escaping (Bool) -> Void) {
        print("Saving driver with Aadhaar: \(driver.aadhaarNumber), documentId: \(documentId)")
        
        let driverData: [String: Any] = [
            "id": driver.id.uuidString,
            "firstName": driver.firstName,
            "lastName": driver.lastName,
            "aadhaarNumber": driver.aadhaarNumber,
            "age": driver.age,
            "contactNumber": driver.contactNumber,
            "licenseNumber": driver.licenseNumber ?? "",
            "licenseValidUpto": driver.licenseValidUpto ?? "",
            "role": driver.role.rawValue,
            "gender": driver.gender?.rawValue ?? "",
            "email": driver.email ?? ""
        ]

        db.collection("Drivers").document(documentId).setData(driverData) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                self.errorMessage = "Error saving driver: \(error.localizedDescription)"
                print("Firebase error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("Driver successfully saved to Firestore with ID: \(documentId)")
            completion(true)
        }
    }
    
    func delete(driver: Driver) {
        // Use Aadhaar number as document ID
        let documentId = driver.aadhaarNumber
        
        isLoading = true
        
        // Delete from Firestore
        db.collection("Drivers").document(documentId).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error deleting driver: \(error.localizedDescription)"
                print("Delete error: \(error.localizedDescription)")
                return
            }
            
            print("Driver successfully deleted from Firestore")
            
            // Remove from local array if Firebase deletion was successful
            if let index = self.drivers.firstIndex(where: { $0.aadhaarNumber == driver.aadhaarNumber }) {
                self.recentlyDeleted = self.drivers.remove(at: index)
                print("Driver removed from local array")
            }
        }
    }
    
    func undoDelete() {
        guard let driver = recentlyDeleted else { return }
        
        isLoading = true
        
        // Add back to Firestore using Aadhaar as document ID
        saveDriverToFirestore(driver: driver, documentId: driver.aadhaarNumber) { [weak self] success in
            guard let self = self else { return }
            self.isLoading = false
            
            if success {
                self.drivers.append(driver)
                self.recentlyDeleted = nil
            }
        }
    }
    
    func add(driver: Driver) {
        // Validate the Aadhaar number is not empty
        if driver.aadhaarNumber.isEmpty {
            self.errorMessage = "Cannot add driver: Aadhaar number is empty"
            return
        }
        
        // Check if driver with this Aadhaar already exists
        if drivers.contains(where: { $0.aadhaarNumber == driver.aadhaarNumber }) {
            self.errorMessage = "Driver with Aadhaar number \(driver.aadhaarNumber) already exists"
            return
        }
        
        isLoading = true
        
        // Create a new driver with the Aadhaar as document ID
        var driverWithDocId = driver
        driverWithDocId.documentId = driver.aadhaarNumber
        
        // Save to Firestore using Aadhaar as document ID
        saveDriverToFirestore(driver: driverWithDocId, documentId: driver.aadhaarNumber) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // Immediately add to local array to update UI
                DispatchQueue.main.async {
                    self.drivers.append(driverWithDocId)
                    print("Added new driver to local array: \(driver.firstName) \(driver.lastName)")
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Edit Functionality
    
    func update(driver: Driver) {
        // Use the Aadhaar number directly as the documentId
        let aadhaarNumber = driver.aadhaarNumber
        
        // Validate the Aadhaar number is not empty
        if aadhaarNumber.isEmpty {
            self.errorMessage = "Cannot update driver: Aadhaar number is empty"
            return
        }
        
        isLoading = true
        print("Updating driver with Aadhaar number as document ID: \(aadhaarNumber)")
        
        // Create updated driver with Aadhaar as documentId
        var updatedDriver = driver
        updatedDriver.documentId = aadhaarNumber
        
        // Update in Firestore using Aadhaar number as document ID
        saveDriverToFirestore(driver: updatedDriver, documentId: aadhaarNumber) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                // Update in local array immediately
                DispatchQueue.main.async {
                    if let index = self.drivers.firstIndex(where: { $0.aadhaarNumber == aadhaarNumber }) {
                        self.drivers[index] = updatedDriver
                        print("Updated driver in local array at index \(index)")
                    } else {
                        // If driver doesn't exist locally, add it
                        self.drivers.append(updatedDriver)
                        print("Added updated driver to local array")
                    }
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    // Refresh function to manually fetch drivers
    func refreshDrivers() {
        fetchDrivers()
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
    @State private var showingDeleteConfirmation = false
    @State private var driverToDelete: Driver?
    @State private var showingContextMenu = false
    @State private var selectedDriver: Driver?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredDrivers.isEmpty {
                    emptyStateView
                } else {
                    driversListView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Staff Details")
            .toolbar {
                if !viewModel.isLoading {
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
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Driver?"),
                    message: Text("Are you sure you want to delete this driver? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let driverToDelete = driverToDelete {
                            withAnimation {
                                viewModel.delete(driver: driverToDelete)
                            }
                        }
                        driverToDelete = nil
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
                viewModel.fetchDrivers()
            }
            .onChange(of: viewModel.errorMessage) { errorMessage in
                if errorMessage != nil {
                    showingError = true
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading staff details...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.xmark")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))

            Text("No Drivers Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("Tap the button below to add a new driver.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showingAddDriver = true
            }) {
                Text("Add Driver")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 10)
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    struct DriverRow: View {
        let driver: Driver
        @Binding var selectedDriver: Driver?
        @Binding var showingContextMenu: Bool
        @Binding var editingDriver: Driver?
        @Binding var driverToDelete: Driver?
        @Binding var showingDeleteConfirmation: Bool

        var body: some View {
            DriverCard(driver: driver)
                .onTapGesture {
                    selectedDriver = driver
                }
                .onLongPressGesture {
                    selectedDriver = driver
                    showingContextMenu = true
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .confirmationDialog(
                    "Driver Options",
                    isPresented: $showingContextMenu,
                    presenting: selectedDriver
                ) { driver in
                    Button("Edit") {
                        editingDriver = driver
                    }

                    Button("Delete", role: .destructive) {
                        driverToDelete = driver
                        showingDeleteConfirmation = true
                    }

                    Button("Cancel", role: .cancel) {}
                } message: { driver in
                    Text("\(driver.firstName) - \(driver.role.rawValue)")
                }
        }
    }

    private var driversListView: some View {
        List {
            ForEach(viewModel.filteredDrivers) { driver in
                DriverRow(
                    driver: driver,
                    selectedDriver: $selectedDriver,
                    showingContextMenu: $showingContextMenu,
                    editingDriver: $editingDriver,
                    driverToDelete: $driverToDelete,
                    showingDeleteConfirmation: $showingDeleteConfirmation
                )
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchDrivers()
        }
    }
}


struct DriverCard: View {
    var driver: Driver
    var onDelete: (() -> Void)? = nil

    @State private var licenseStatus: String = ""

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 26))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(driver.firstName)
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
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
        }
        .onAppear {
            updateLicenseStatus()
        }
        .onChange(of: driver.licenseValidUpto) { _ in
            updateLicenseStatus()
        }
    }

    private func updateLicenseStatus() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current

        let licenseDateString = driver.licenseValidUpto ?? ""

        if let validUptoDate = dateFormatter.date(from: licenseDateString) {
            let currentDate = Calendar.current.startOfDay(for: Date())
            let strippedValidUptoDate = Calendar.current.startOfDay(for: validUptoDate)

            licenseStatus = strippedValidUptoDate >= currentDate ? "Active" : "Expired"
        } else {
            licenseStatus = "Unknown"
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
    @State private var isFocused = false
    @State private var showAlert = false
    
    @State private var isAgeValid = true // Start as true to avoid initial red border

    var editingDriver: Driver?

    var body: some View {
        
        NavigationStack {
            Form {
                Section(header: Text("Personnel Details")) {
                    TextField("First Name", text: $firstName)
                        .textInputAutocapitalization(.words)
                    TextField("Last Name", text: $lastName)
                        .textInputAutocapitalization(.words)
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
                                .textFieldStyle(.plain)
                                .keyboardType(.numberPad)
                                
                                
                                .onChange(of: age) { newValue in
                                    age = String(newValue.prefix(3).filter { $0.isNumber })
                                    
                                    if !isFocused {
                                        if age.isEmpty {
                                            isAgeValid = true
                                        } else if let val = Int(age) {
                                            if val > 120 {
                                                age = "120"
                                            }
                                            if val < 18 {
                                                isAgeValid = false
                                                showAlert = true
                                            } else {
                                                isAgeValid = true
                                                showAlert = false
                                            }
                                        } else {
                                            isAgeValid = false
                                            showAlert = true
                                        }
                                    } else {
                                        isAgeValid = true // Neutral during typing
                                        showAlert = false
                                    }
                                }
                                .alert(isPresented: $showAlert) {
                                    Alert(
                                        title: Text("Age must be greater than 18"),
                                        dismissButton: .cancel(Text("OK"))
                                    )
                                }


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
                            .autocapitalization(.allCharacters)
                            .textFieldStyle(.plain)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: licenseNumber) { _ in
                                let clean = licenseNumber
                                    .replacingOccurrences(of: "-", with: "")
                                    .filter { $0.isLetter || $0.isNumber }
                                    .uppercased()
                                
                                var result = ""
                                let pattern = [2, 2, 4, 3, 4] // AA-DD-YYYY-NNN-DDDD
                                var index = clean.startIndex
                                
                                for length in pattern {
                                    guard index < clean.endIndex else { break }
                                    let nextIndex = clean.index(index, offsetBy: length, limitedBy: clean.endIndex) ?? clean.endIndex
                                    result += clean[index..<nextIndex]
                                    if nextIndex != clean.endIndex {
                                        result += "-"
                                    }
                                    index = nextIndex
                                }
                                
                                licenseNumber = result
                            }

                        
                            


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
                         
                            if let val = Int(age), val >= 18 {
                                isAgeValid = true
                                showAlert = false
                                // Proceed with saving logic
                                print("Age is valid. Proceed to save.")
                            } else {
                                isAgeValid = false
                                showAlert = true
                            }
                        
                        

                        if editingDriver == nil {
                            viewModel.add(driver: driver)
                        } else {
                            viewModel.update(driver: driver)
                        }
                        dismiss()
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Age must be greater than 18"),
                            dismissButton: .default(Text("OK"))
                        )
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
        // Remove hyphens and filter only numeric digits, up to 12
        let digits = self.replacingOccurrences(of: "-", with: "").filter { $0.isNumber }.prefix(12)
        
        // Convert to string for formatting
        var formatted = String(digits)
        
        // Insert hyphens based on length
        if formatted.count > 4 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 4))
        }
        if formatted.count > 9 {
            formatted.insert("-", at: formatted.index(formatted.startIndex, offsetBy: 9))
        }
        
        // Return formatted string or empty string for no digits
        return formatted
    }
}

// Extension to format License Number
private func isValidLicenseNumber(_ license: String) -> Bool {
    let pattern = "^[A-Z]{2}-[0-9]{2}-[0-9]{3}-[0-9]{4}-[0-9]{4}$"
    let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
    guard predicate.evaluate(with: license) else { return false }
    
    let parts = license.split(separator: "-")
    if let year = Int(parts[2]), year < 1900 || year > 2025 {
        return false
    }
    return true
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
