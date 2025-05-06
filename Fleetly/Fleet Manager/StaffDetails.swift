import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import AVFoundation
import FirebaseStorage

// MARK: - Model

// Enum for Role
enum Role: String, CaseIterable, Identifiable {
    case driver = "Driver"
    case maintenance = "Maintenance"
    
    var id: String { self.rawValue }
}

// Enum for Gender
enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    
    var id: String { self.rawValue }
}

// MARK: - ViewModel
class UserManagerViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var searchText: String = ""
    @Published var recentlyDeleted: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var roleFilter: Role? = nil
    @Published var availabilityFilter: Bool? = nil
    @Published var activeFilters: [String] = []
    @Published var selectedUser: User? = nil
    
    private var db = Firestore.firestore()
    
    init() {
        fetchUsers()
    }
    func approveUser(userId: String) {
         guard let index = users.firstIndex(where: { $0.id == userId }) else { return }
         
         var user = users[index]
         user.isApproved = true
         
         let userData: [String: Any] = [
             "isApproved": true
         ]
         
         db.collection("users").document(userId).updateData(userData) { [weak self] error in
             if let error = error {
                 self?.errorMessage = "Error approving user: \(error.localizedDescription)"
                 print("Update error: \(error.localizedDescription)")
                 return
             }
             
             DispatchQueue.main.async {
                 self?.users[index] = user
                 print("User approved: \(user.name)")
             }
         }
     }
    func rejectUser(userId: String) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // Step 1: Fetch user details to get document URLs
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user for deletion: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("No user data found.")
                return
            }
            
            // Get file URLs if they exist
            if let aadharUrl = data["aadharDocUrl"] as? String {
                self.deleteFileFromStorage(urlString: aadharUrl)
            }
            
            if let licenseUrl = data["licenseDocUrl"] as? String {
                self.deleteFileFromStorage(urlString: licenseUrl)
            }
            
            // Step 2: Delete Firestore document
            db.collection("users").document(userId).delete { error in
                if let error = error {
                    print("Error deleting Firestore document: \(error.localizedDescription)")
                } else {
                    print("User Firestore document deleted successfully.")
                }
            }
            
            
        }
    }

    /// Helper function to delete a file from Firebase Storage
    private func deleteFileFromStorage(urlString: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: urlString)
        storageRef.delete { error in
            if let error = error {
                print("Error deleting file from storage: \(error.localizedDescription)")
            } else {
                print("File deleted from storage successfully.")
            }
        }
    }

    var filteredUsers: [User] {
        let filtered = users.filter { user in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
            user.name.lowercased().contains(searchText.lowercased()) ||
            user.phone.contains(searchText) ||
            user.aadharNumber?.contains(searchText) ?? false ||
            user.drivingLicenseNumber?.lowercased().contains(searchText.lowercased()) ?? false
            
            // Role filter
            let matchesRole = roleFilter == nil || user.role == roleFilter!.rawValue.lowercased()
            
            // Availability filter
            let matchesAvailability = availabilityFilter == nil || user.isAvailable == availabilityFilter
            
            return matchesSearch && matchesRole && matchesAvailability
        }
        
        // Sort: unapproved first, then by name
        return filtered.sorted {
            if let approved1 = $0.isApproved, let approved2 = $1.isApproved {
                if approved1 != approved2 {
                    return !approved1 // Show unapproved first
                }
            }
            return $0.name < $1.name
        }
    }
    
    func updateActiveFilters() {
        activeFilters.removeAll()
        
        if roleFilter != nil {
            activeFilters.append("Role: \(roleFilter!.rawValue)")
        }
        
        if availabilityFilter != nil {
            activeFilters.append(availabilityFilter! ? "Available" : "Not Available")
        }
    }
    
    func fetchUsers() {
        isLoading = true
        print("Fetching users from Firestore...")

        db.collection("users").whereField("role", in: ["driver", "maintenance"]).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            defer { self.isLoading = false }

            if let error = error {
                self.errorMessage = "Error fetching users: \(error.localizedDescription)"
                print(self.errorMessage!)
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No documents found.")
                return
            }

            print("Number of users fetched: \(documents.count)")

            var loadedUsers: [User] = []

            for document in documents {
                let data = document.data()

                guard
                    let name = data["name"] as? String,
                    let email = data["email"] as? String,
                    let phone = data["phone"] as? String,
                    let role = data["role"] as? String
                else {
                    print("Skipping document due to missing fields: \(document.documentID)")
                    continue
                }
                
                // Parse optional fields
                let gender = data["gender"] as? String
                let age = data["age"] as? Int
                let disability = data["disability"] as? String
                let aadharNumber = data["aadharNumber"] as? String
                let drivingLicenseNumber = data["drivingLicenseNumber"] as? String
                let aadharDocUrl = data["aadharDocUrl"] as? String
                let licenseDocUrl = data["licenseDocUrl"] as? String
                let isApproved = data["isApproved"] as? Bool ?? true
                let isAvailable = data["isAvailable"] as? Bool ?? true

                let user = User(
                    id: document.documentID,
                    name: name,
                    email: email,
                    phone: phone,
                    role: role,
                    gender: gender,
                    age: age,
                    disability: disability,
                    aadharNumber: aadharNumber,
                    drivingLicenseNumber: drivingLicenseNumber,
                    aadharDocUrl: aadharDocUrl,
                    licenseDocUrl: licenseDocUrl,
                    isApproved: isApproved,
                    isAvailable: isAvailable
                )

                loadedUsers.append(user)
                print("Loaded user with Aadhaar: \(aadharNumber ?? "N/A"), documentId: \(document.documentID)")
            }

            DispatchQueue.main.async {
                self.users = loadedUsers
                print("Users successfully loaded: \(self.users.count)")
            }
        }
    }

    func toggleAvailability(for userId: String) {
        guard let index = users.firstIndex(where: { $0.id == userId }) else { return }
        
        var user = users[index]
        user.isAvailable?.toggle()
        
        let userData: [String: Any] = [
            "isAvailable": user.isAvailable ?? true
        ]
        
        db.collection("users").document(userId).updateData(userData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error updating availability: \(error.localizedDescription)"
                print("Update error: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.users[index] = user
                print("Availability toggled for user \(user.name)")
            }
        }
    }

    private func saveUserToFirestore(user: User, documentId: String, completion: @escaping (Bool) -> Void) {
        print("Saving user with Aadhaar: \(user.aadharNumber ?? "N/A"), documentId: \(documentId)")
        
        let userData: [String: Any] = [
            "uid": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "role": user.role,
            "gender": user.gender ?? "",
            "age": user.age ?? 0,
            "disability": user.disability ?? "",
            "aadharNumber": user.aadharNumber ?? "",
            "drivingLicenseNumber": user.drivingLicenseNumber ?? "",
            "aadharDocUrl": user.aadharDocUrl ?? "",
            "licenseDocUrl": user.licenseDocUrl ?? "",
            "isApproved":true,
            "isAvailable": user.isAvailable ?? true
        ]

        db.collection("users").document(documentId).setData(userData) { [weak self] error in
            guard let self = self else {
                completion(false)
                return
            }

            if let error = error {
                self.errorMessage = "Error saving user: \(error.localizedDescription)"
                print("Firebase error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            print("User successfully saved to Firestore with ID: \(documentId)")
            completion(true)
        }
    }
    
    func delete(user: User) {
        let documentId = user.id
        
        isLoading = true
        
        db.collection("users").document(documentId).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error deleting user: \(error.localizedDescription)"
                print("Delete error: \(error.localizedDescription)")
                return
            }
            
            print("User successfully deleted from Firestore")
            
            if let index = self.users.firstIndex(where: { $0.id == user.id }) {
                self.recentlyDeleted = self.users.remove(at: index)
                print("User removed from local array")
            }
        }
    }
    
    func undoDelete() {
        guard let user = recentlyDeleted else { return }
        
        isLoading = true
        
        saveUserToFirestore(user: user, documentId: user.id) { [weak self] success in
            guard let self = self else { return }
            self.isLoading = false
            
            if success {
                self.users.append(user)
                self.recentlyDeleted = nil
            }
        }
    }
    
    func add(user: User, aadharImage: UIImage?, licenseImage: UIImage?, completion: @escaping (Bool) -> Void) {
        // Generate password
        let password = generatePassword(from: user.name, aadhar: user.aadharNumber ?? "")
        
        // Create user in Firebase Auth
        createUserAuth(email: user.email, password: password) { [weak self] uid, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                self.errorMessage = "Error creating user: \(error.localizedDescription)"
                print(self.errorMessage!)
                completion(false)
                return
            }
            
            guard let uid = uid else {
                self.errorMessage = "Failed to get UID after user creation"
                completion(false)
                return
            }
            
            // Update user with the UID
            var newUser = user
            newUser.id = uid
            
            // Upload documents if they exist
            let dispatchGroup = DispatchGroup()
            var aadharUrl: String?
            var licenseUrl: String?
            
            if let aadharImage = aadharImage {
                dispatchGroup.enter()
                self.uploadDocument(image: aadharImage, userId: uid, type: "aadhar") { url in
                    aadharUrl = url
                    dispatchGroup.leave()
                }
            }
            
            if let licenseImage = licenseImage, user.role == "driver" {
                dispatchGroup.enter()
                self.uploadDocument(image: licenseImage, userId: uid, type: "license") { url in
                    licenseUrl = url
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Update user with document URLs
                newUser.aadharDocUrl = aadharUrl
                newUser.licenseDocUrl = licenseUrl
                
                // Save to Firestore
                self.saveUserToFirestore(user: newUser, documentId: uid) { success in
                    if success {
                        DispatchQueue.main.async {
                            self.users.append(newUser)
                            print("Added new user to local array: \(newUser.name)")
                        }
                    }
                    completion(success)
                }
            }
        }
    }
    
     func uploadDocument(image: UIImage, userId: String, type: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let documentRef = storageRef.child("documents/\(userId)/\(type).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        documentRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Error uploading \(type): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            documentRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    func update(user: User) {
        let documentId = user.id
        
        if documentId.isEmpty {
            self.errorMessage = "Cannot update user: Document ID is empty"
            return
        }
        
        isLoading = true
        print("Updating user with document ID: \(documentId)")
        
        saveUserToFirestore(user: user, documentId: documentId) { [weak self] success in
            guard let self = self else { return }
            
            if success {
                DispatchQueue.main.async {
                    if let index = self.users.firstIndex(where: { $0.id == documentId }) {
                        self.users[index] = user
                        print("Updated user in local array at index \(index)")
                    } else {
                        self.users.append(user)
                        print("Added updated user to local array")
                    }
                    self.isLoading = false
                }
            } else {
                self.isLoading = false
            }
        }
    }
    
    func refreshUsers() {
        fetchUsers()
    }
    
    private func generatePassword(from name: String, aadhar: String) -> String {
        let firstName = name.split(separator: " ").first?.lowercased() ?? ""
        var firstNamePart = String(firstName.prefix(4))
        while firstNamePart.count < 4 {
            firstNamePart += firstName
        }
        firstNamePart = String(firstNamePart.prefix(4))
        let aadharDigits = aadhar.replacingOccurrences(of: "-", with: "").prefix(4)
        return firstNamePart + aadharDigits
    }
    
    private func createUserAuth(email: String, password: String, completion: @escaping (String?, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(nil, error)
            } else if let user = authResult?.user {
                completion(user.uid, nil)
            } else {
                completion(nil, NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
            }
        }
    }
}

// MARK: - Main View
struct UserManagerView: View {
    @StateObject private var viewModel = UserManagerViewModel()
    @State private var showingAddUser = false
    @State private var editingUser: User?
    @State private var showingDeleteConfirmation = false
    @State private var userToDelete: User?
    @State private var showingContextMenu = false
    @State private var showingError = false
    @State private var showingFilters = false
    @State private var showingUserDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredUsers.isEmpty {
                    emptyStateView
                } else {
                    usersListView
                }
            }
            .environmentObject(viewModel)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Staff Details")
            .toolbar {
                if !viewModel.isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddUser = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.title3)
                                .overlay(alignment: .topTrailing) {
                                    if !viewModel.activeFilters.isEmpty {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .sheet(isPresented: $showingAddUser) {
                UserFormView(viewModel: viewModel, editingUser: nil)
            }
            .sheet(item: $editingUser) { user in
                UserFormView(viewModel: viewModel, editingUser: user)
            }
            .sheet(item: $viewModel.selectedUser) { user in
                UserDetailView(user: user, viewModel: viewModel)
            }
            .confirmationDialog("Filter Options", isPresented: $showingFilters) {
                Button("All Roles") {
                    viewModel.roleFilter = nil
                    viewModel.updateActiveFilters()
                }
                Button("Drivers Only") {
                    viewModel.roleFilter = .driver
                    viewModel.updateActiveFilters()
                }
                Button("Maintenance Only") {
                    viewModel.roleFilter = .maintenance
                    viewModel.updateActiveFilters()
                }
                
                Divider()
                
                Button("All Availability") {
                    viewModel.availabilityFilter = nil
                    viewModel.updateActiveFilters()
                }
                Button("Available Only") {
                    viewModel.availabilityFilter = true
                    viewModel.updateActiveFilters()
                }
                Button("Not Available Only") {
                    viewModel.availabilityFilter = false
                    viewModel.updateActiveFilters()
                }
                
                Divider()
                
                Button("Reset All Filters") {
                    viewModel.roleFilter = nil
                    viewModel.availabilityFilter = nil
                    viewModel.updateActiveFilters()
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if !viewModel.activeFilters.isEmpty {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.activeFilters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            viewModel.roleFilter = nil
                            viewModel.availabilityFilter = nil
                            viewModel.updateActiveFilters()
                        } label: {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.activeFilters)
                }
            }
            .overlay(alignment: .bottom) {
                if let _ = viewModel.recentlyDeleted {
                    UndoToast {
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
                    title: Text("Delete User?"),
                    message: Text("Are you sure you want to delete this user? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let userToDelete = userToDelete {
                            withAnimation {
                                viewModel.delete(user: userToDelete)
                            }
                        }
                        userToDelete = nil
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
                viewModel.fetchUsers()
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

            Text(viewModel.searchText.isEmpty ? "No Staff Found" : "No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(viewModel.searchText.isEmpty ?
                "Tap the button below to add a new staff member." :
                "No staff members match your search criteria.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if viewModel.searchText.isEmpty {
                Button(action: {
                    showingAddUser = true
                }) {
                    Text("Add Staff")
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
        }
        .padding()
    }

    private var usersListView: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                UserCard(user: user)
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.toggleAvailability(for: user.id)
                        } label: {
                            Label(
                                user.isAvailable == true ? "Set Unavailable" : "Set Available",
                                systemImage: user.isAvailable == true ? "person.fill.xmark" : "person.fill.checkmark"
                            )
                        }
                        .tint(user.isAvailable == true ? .red : .green)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingUser = user
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            editingUser = user
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            userToDelete = user
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedUser = user
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchUsers()
        }
    }
}

struct UserCard: View {
    var user: User
    var onDelete: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(user.isApproved == false ? .orange : (user.isAvailable == true ? .green : .red))
                        .font(.system(size: 26))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user.name)
                                .font(.title3.bold())
                            
                            if user.isApproved == false {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        
                        Text(user.role.capitalized)
                            .font(.subheadline.bold())
                        if let licenseNumber = user.drivingLicenseNumber, !licenseNumber.isEmpty {
                            Text("License: \(licenseNumber)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if user.isApproved == true {
                                                    HStack {
                                                        Text(user.isAvailable == true ? "Available" : "Not Available")
                                                            .font(.subheadline)
                                                            .foregroundColor(user.isAvailable == true ? .green : .red)
                                                    }
                                                } else {
                                                    Text("Pending Approval")
                                                        .font(.subheadline)
                                                        .foregroundColor(.orange)
                                                }
                                            }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
        }
    }
}

// MARK: - User Detail View
struct UserDetailView: View {
    let user: User
    @ObservedObject var viewModel: UserManagerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showRejectConfirmation = false
    @State private var showApproveConfirmation = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Information")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRow(label: "Name", value: user.name)
                        DetailRow(label: "Email", value: user.email)
                        DetailRow(label: "Phone", value: user.phone)
                        DetailRow(label: "Role", value: user.role.capitalized)
                        DetailRow(label: "Gender", value: user.gender?.capitalized ?? "Not specified")
                        DetailRow(label: "Age", value: user.age?.description ?? "Not specified")
                        DetailRow(label: "Disability", value: user.disability ?? "None")
                        DetailRow(label: "Status", value: user.isApproved == false ? "Pending Approval" : "Approved")
                        DetailRow(label: "Availability", value: user.isAvailable == true ? "Available" : "Not Available")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Aadhar Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aadhar Details")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRow(label: "Aadhar Number", value: user.aadharNumber ?? "Not provided")
                        
                        if let aadharUrl = user.aadharDocUrl {
                            DocumentPreview(title: "Aadhar Proof", imageUrl: aadharUrl)
                        } else {
                            Text("No Aadhar proof uploaded")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // License Section (for drivers)
                    if user.role == "driver" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("License Details")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            DetailRow(label: "License Number", value: user.drivingLicenseNumber ?? "Not provided")
                            
                            if let licenseUrl = user.licenseDocUrl {
                                DocumentPreview(title: "License Proof", imageUrl: licenseUrl)
                            } else {
                                Text("No License proof uploaded")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    if user.isApproved == false {
                        VStack(spacing: 12) {
                            Button(action: {
                                showRejectConfirmation = true
                            }) {
                                Text("Reject Request")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .confirmationDialog(
                                "Are you sure you want to reject this request?",
                                isPresented: $showRejectConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Reject", role: .destructive) {
                                    viewModel.rejectUser(userId: user.id)
                                    dismiss()
                                }
                                Button("Cancel", role: .cancel) { }
                            }
                            
                            Button(action: {
                                showApproveConfirmation = true
                            }) {
                                Text("Approve Request")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .confirmationDialog(
                                "Are you sure you want to approve this request?",
                                isPresented: $showApproveConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Approve", role: .none) {
                                    viewModel.approveUser(userId: user.id)
                                    dismiss()
                                }
                                Button("Cancel", role: .cancel) { }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle(user.name)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//struct DetailRow: View {
//    let label: String
//    let value: String
//    
//    var body: some View {
//        HStack {
//            Text(label)
//                .foregroundColor(.gray)
//            Spacer()
//            Text(value)
//                .multilineTextAlignment(.trailing)
//        }
//    }
//}

struct DocumentPreview: View {
    let title: String
    let imageUrl: String
    
    @State private var image: UIImage? = nil
    @State private var showingFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .onTapGesture {
                        showingFullScreen = true
                    }
                    .sheet(isPresented: $showingFullScreen) {
                        FullScreenImageView(image: image)
                    }
            } else {
                ProgressView()
                    .frame(height: 100)
            }
        }
        .onAppear {
            loadImageFromUrl()
        }
    }
    
    private func loadImageFromUrl() {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }.resume()
    }
}

struct FullScreenImageView: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        }
    }
}

// MARK: - Form View
struct UserFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: UserManagerViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var currentDocumentType: DocumentType = .aadhar
    
    enum DocumentType {
        case aadhar, license
    }

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: Role = .driver
    @State private var gender: Gender = .male
    @State private var age = ""
    @State private var disability = ""
    @State private var aadharNumber = ""
    @State private var drivingLicenseNumber = ""
    @State private var isAvailable = true
    @State private var showAlert = false
    @State private var isAgeValid = true
    @FocusState private var focusedField: Field?
    @State private var aadharPhotoItem: PhotosPickerItem?
    @State private var licensePhotoItem: PhotosPickerItem?
    @State private var aadharImage: UIImage?
    @State private var licenseImage: UIImage?
    @State private var isLoading = false

    enum Field {
        case age
    }

    var editingUser: User?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personnel Details")) {
                    TextField("Full Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .disabled(editingUser != nil)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.numberPad)
                        .onChange(of: phone) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 10 {
                                phone = String(digits.prefix(10))
                            } else {
                                phone = digits
                            }
                        }
                    Picker("Role", selection: $role) {
                        ForEach(Role.allCases) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Aadhaar Number", text: $aadharNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: aadharNumber) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            if digits.count > 12 {
                                aadharNumber = String(digits.prefix(12)).formatAadhaar()
                            } else {
                                aadharNumber = digits.formatAadhaar()
                            }
                        }
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .age)
                        .onChange(of: age) { newValue in
                            age = String(newValue.prefix(3).filter { $0.isNumber })
                        }
                        .onChange(of: focusedField) { field in
                            // Only validate when losing focus
                            if field != .age {
                                validateAge()
                            }
                        }
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Additional Details")) {
                    if role == .driver {
                        TextField("Driving License Number", text: $drivingLicenseNumber)
                            .autocapitalization(.allCharacters)
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: drivingLicenseNumber) { _ in
                                let clean = drivingLicenseNumber
                                    .replacingOccurrences(of: "-", with: "")
                                    .filter { $0.isLetter || $0.isNumber }
                                    .uppercased()
                                
                                var result = ""
                                if clean.count >= 2 {
                                    result += clean.prefix(2)
                                    if clean.count > 2 {
                                        result += "-"
                                        result += clean.dropFirst(2).prefix(13)
                                    }
                                } else {
                                    result = clean
                                }
                                
                                drivingLicenseNumber = result
                            }
                    }
                    TextField("Disability (if any)", text: $disability)
                    Toggle("Available", isOn: $isAvailable)
                }
                
                Section(header: Text("Document Upload")) {
                    // Aadhar Upload
                    VStack(alignment: .leading) {
                        Text("Aadhar Proof")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Button {
                                currentDocumentType = .aadhar
                                showingImagePicker = true
                            } label: {
                                Label(
                                    aadharImage != nil ? "Change Aadhar" : "Upload",
                                    systemImage: "photo"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                currentDocumentType = .aadhar
                                requestCameraPermission()
                            } label: {
                                Label("Capture", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if let aadharImage = aadharImage {
                            Image(uiImage: aadharImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                        } else {
                            Text("No Aadhar proof selected")
                                .foregroundColor(.gray)
                                .frame(height: 40)
                        }
                    }
                    
                    // License Upload (for drivers)
                    if role == .driver {
                        VStack(alignment: .leading) {
                            Text("License Proof")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Button {
                                    currentDocumentType = .license
                                    showingImagePicker = true
                                } label: {
                                    Label(
                                        licenseImage != nil ? "Change License" : "Upload",
                                        systemImage: "photo"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    currentDocumentType = .license
                                    requestCameraPermission()
                                } label: {
                                    Label("Capture", systemImage: "camera")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if let licenseImage = licenseImage {
                                Image(uiImage: licenseImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(8)
                            } else {
                                Text("No License proof selected")
                                    .foregroundColor(.gray)
                                    .frame(height: 40)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotoPicker(selectedImage: currentDocumentType == .aadhar ? $aadharImage : $licenseImage)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedImage: currentDocumentType == .aadhar ? $aadharImage : $licenseImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Age"),
                    message: Text("Age must be at least 18 years."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle(editingUser == nil ? "Add Staff" : "Edit Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            if validateAge() {
                                saveUser()
                            }
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
            .onAppear {
                if let user = editingUser {
                    name = user.name
                    email = user.email
                    phone = user.phone
                    role = Role(rawValue: user.role.capitalized) ?? .driver
                    aadharNumber = user.aadharNumber?.formatAadhaar() ?? ""
                    age = user.age.map { String($0) } ?? ""
                    disability = user.disability ?? ""
                    drivingLicenseNumber = user.drivingLicenseNumber ?? ""
                    isAvailable = user.isAvailable ?? true
                    gender = user.gender.flatMap { Gender(rawValue: $0) } ?? .male
                    
                    // Load existing document images if available
                    if let aadharUrl = user.aadharDocUrl {
                        loadImage(from: aadharUrl) { image in
                            aadharImage = image
                        }
                    }
                    
                    if let licenseUrl = user.licenseDocUrl {
                        loadImage(from: licenseUrl) { image in
                            licenseImage = image
                        }
                    }
                }
            }
        }
    }
    
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    showingCamera = true
                } else {
                    // Show alert that camera access is required
                    showAlert = true
                    viewModel.errorMessage = "Camera access is required to capture documents"
                }
            }
        }
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    private func validateAge() -> Bool {
        guard !age.isEmpty else {
            isAgeValid = true
            return true
        }
        
        if let ageInt = Int(age), ageInt >= 18 {
            isAgeValid = true
            return true
        } else {
            isAgeValid = false
            showAlert = true
            return false
        }
    }
    
    private func saveUser() {
        isLoading = true
        
        let user = User(
            id: editingUser?.id ?? UUID().uuidString, // Temporary ID for new user
            name: name,
            email: email,
            phone: phone,
            role: role.rawValue.lowercased(),
            gender: gender.rawValue,
            age: Int(age),
            disability: disability.isEmpty ? nil : disability,
            aadharNumber: aadharNumber.replacingOccurrences(of: "-", with: ""),
            drivingLicenseNumber: role == .driver ? drivingLicenseNumber : nil,
            isAvailable: isAvailable
        )
        
        if editingUser == nil {
            viewModel.add(user: user, aadharImage: aadharImage, licenseImage: licenseImage) { success in
                isLoading = false
                if success {
                    dismiss()
                }
            }
        } else {
            // For editing, we need to handle document updates differently
            let dispatchGroup = DispatchGroup()
            var aadharUrl: String?
            var licenseUrl: String?
            
            if let aadharImage = aadharImage {
                dispatchGroup.enter()
                viewModel.uploadDocument(image: aadharImage, userId: user.id, type: "aadhar") { url in
                    aadharUrl = url
                    dispatchGroup.leave()
                }
            }
            
            if let licenseImage = licenseImage, user.role == "driver" {
                dispatchGroup.enter()
                viewModel.uploadDocument(image: licenseImage, userId: user.id, type: "license") { url in
                    licenseUrl = url
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                var updatedUser = user
                updatedUser.aadharDocUrl = aadharUrl ?? editingUser?.aadharDocUrl
                updatedUser.licenseDocUrl = licenseUrl ?? editingUser?.licenseDocUrl
                
                viewModel.update(user: updatedUser)
                isLoading = false
                dismiss()
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        phone.count == 10 &&
        aadharNumber.replacingOccurrences(of: "-", with: "").count == 12 &&
        !age.isEmpty &&
        (role != .driver || !drivingLicenseNumber.isEmpty) &&
        isAgeValid &&
        (editingUser != nil || aadharImage != nil) && // Require Aadhar for new users
        (role != .driver || editingUser != nil || licenseImage != nil) // Require license for new drivers
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Extension to format Aadhaar number
extension String {
    func formatAadhaar() -> String {
        let digits = self.replacingOccurrences(of: "-", with: "").filter { $0.isNumber }.prefix(12)
        var formatted = String(digits)
        
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
struct UndoToast: View {
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
            .background(.ultraThinMaterial)
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
    UserManagerView()
}
