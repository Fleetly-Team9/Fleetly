import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - ColorBlindModeManager
class ColorBlindModeManager: ObservableObject {
    @Published var isColorBlindMode: Bool {
        didSet {
            UserDefaults.standard.set(isColorBlindMode, forKey: "isColorBlindMode")
            UserDefaults.standard.synchronize()
            print("ColorBlindModeManager: isColorBlindMode set to \(isColorBlindMode)")
        }
    }
    
    init() {
        self.isColorBlindMode = UserDefaults.standard.bool(forKey: "isColorBlindMode")
    }
}

extension Color {
    static let cbBlue = Color(red: 0.0, green: 114/255, blue: 178/255)   // #0072B2
    static let cbOrange = Color(red: 230/255, green: 159/255, blue: 0.0) // #E69F00
}

struct showProfileView: View {
    @State private var profileImage: Image = Image("exampleImage")
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthViewModel()
    @State private var userData: [String: Any] = [:]
    @State private var isLoading = true
    @State private var showPasswordResetAlert = false
    @State private var passwordResetMessage: String?
    @StateObject private var colorBlindManager = ColorBlindModeManager()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    private var primaryColor: Color {
        colorBlindManager.isColorBlindMode ? .blue : .blue
    }
    
    private var accentColor: Color {
        colorBlindManager.isColorBlindMode ? .orange : .red
    }
    
    var body: some View {
        NavigationStack {
            Form {
                ProfileImageSection(
                    profileImage: $profileImage,
                    selectedItem: $selectedItem,
                    imageData: $imageData,
                    isColorBlindMode: colorBlindManager.isColorBlindMode,
                    uploadProfileImage: uploadProfileImage,
                    deleteProfileImage: deleteProfileImage
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                Section(header: Text("Fleet Manager Details")) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        let fullName = userData["name"] as? String ?? ""
                        let nameComponents = fullName.split(separator: " ").map { String($0) }
                        let firstName = nameComponents.first ?? ""
                        let lastName = nameComponents.dropFirst().joined(separator: " ")
                        
                        FleetProfileRow(title: "First Name", value: .constant(firstName), isEditable: false)
                        FleetProfileRow(title: "Last Name", value: .constant(lastName), isEditable: false)
                        FleetProfileRow(title: "Phone Number", value: .constant(userData["phone"] as? String ?? ""), isEditable: false)
                        FleetProfileRow(title: "Email ID", value: .constant(userData["email"] as? String ?? ""), isEditable: false)
                    }
                }
                
                Section {
                    Toggle("Color Blind Mode", isOn: $colorBlindManager.isColorBlindMode)
                        .tint(primaryColor)
                        .onChange(of: colorBlindManager.isColorBlindMode) { newValue in
                            print("showProfileView: isColorBlindMode set to \(newValue)")
                            UserDefaults.standard.synchronize()
                            print("showProfileView UserDefaults isColorBlindMode: \(UserDefaults.standard.bool(forKey: "isColorBlindMode"))")
                        }
                }
                
                Section {
                    Button(action: {
                        sendPasswordResetEmail()
                    }) {
                        Text("Reset Password")
                            .foregroundColor(primaryColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section {
                    Button(action: {
                        authVM.logout()
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let loginView = LoginView(authVM: authVM)
                            let hostingController = UIHostingController(rootView: loginView)
                            window.rootViewController = hostingController
                            window.makeKeyAndVisible()
                        }
                    }) {
                        Text("Sign Out")
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Fleet Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryColor)
                }
            }
            .onAppear {
                fetchUserData()
                loadProfileImage()
                print("showProfileView onAppear: isColorBlindMode = \(colorBlindManager.isColorBlindMode)")
                print("showProfileView onAppear UserDefaults isColorBlindMode: \(UserDefaults.standard.bool(forKey: "isColorBlindMode"))")
            }
            .alert(isPresented: $showPasswordResetAlert) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text(passwordResetMessage ?? "An error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists, let data = document.data() {
                self.userData = data
                self.isLoading = false
            } else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
                self.isLoading = false
            }
        }
    }
    
    private func uploadProfileImage(data: Data) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let imageRef = storage.child("profileImages/\(userId).jpg")
        
        imageRef.putData(data, metadata: nil) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                if let downloadURL = url?.absoluteString {
                    db.collection("users").document(userId).updateData([
                        "profileImageURL": downloadURL
                    ])
                }
            }
        }
        
        UserDefaults.standard.set(data, forKey: "profileImage")
    }
    
    private func loadProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if let savedData = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: savedData) {
            profileImage = Image(uiImage: uiImage)
            imageData = savedData
            return
        }
        
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists,
               let data = document.data(),
               let imageURL = data["profileImageURL"] as? String,
               let url = URL(string: imageURL) {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    if let data = data, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.profileImage = Image(uiImage: uiImage)
                            self.imageData = data
                            UserDefaults.standard.set(data, forKey: "profileImage")
                        }
                    }
                }.resume()
            }
        }
    }
    
    private func deleteProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let imageRef = storage.child("profileImages/\(userId).jpg")
        
        imageRef.delete { error in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
                return
            }
            
            db.collection("users").document(userId).updateData([
                "profileImageURL": FieldValue.delete()
            ])
            
            UserDefaults.standard.removeObject(forKey: "profileImage")
            
            DispatchQueue.main.async {
                self.profileImage = Image("exampleImage")
                self.imageData = nil
                self.selectedItem = nil
            }
        }
    }
    
    private func sendPasswordResetEmail() {
        guard let email = userData["email"] as? String else {
            passwordResetMessage = "Email not found"
            showPasswordResetAlert = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                passwordResetMessage = "Failed to send reset email: \(error.localizedDescription)"
            } else {
                passwordResetMessage = "Password reset email sent to \(email)"
            }
            showPasswordResetAlert = true
        }
    }
}

// MARK: - Profile Image Section
struct ProfileImageSection: View {
    @Binding var profileImage: Image
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var imageData: Data?
    let isColorBlindMode: Bool
    let uploadProfileImage: (Data) -> Void
    let deleteProfileImage: () -> Void
    
    private var primaryColor: Color {
        isColorBlindMode ? .blue : .blue
    }
    
    private var accentColor: Color {
        isColorBlindMode ? .orange : .red
    }
    
    var body: some View {
        Section {
            VStack(spacing: 15) {
                ZStack {
                    if imageData == nil {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            )
                    } else {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(primaryColor))
                            .offset(x: 35, y: 35)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = Image(uiImage: uiImage)
                            imageData = data
                            uploadProfileImage(data)
                        }
                    }
                }
                
                if imageData != nil {
                    Button(action: {
                        deleteProfileImage()
                    }) {
                        Text("Remove Photo")
                            .font(.subheadline)
                            .foregroundColor(accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    showProfileView()
}
