import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - ImageCacheManager
class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    private func getCacheDirectory() -> URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    private func getCacheURL(for key: String) -> URL {
        getCacheDirectory().appendingPathComponent(key)
    }
    
    func cacheImage(_ image: UIImage, for key: String) {
        // Cache in memory
        cache.setObject(image, forKey: key as NSString)
        
        // Cache on disk
        let cacheURL = getCacheURL(for: key)
        if let data = image.jpegData(compressionQuality: 0.7) {
            try? data.write(to: cacheURL)
        }
    }
    
    func getCachedImage(for key: String) -> UIImage? {
        // Try memory cache first
        if let cachedImage = cache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Try disk cache
        let cacheURL = getCacheURL(for: key)
        if let data = try? Data(contentsOf: cacheURL),
           let image = UIImage(data: data) {
            // Cache in memory for next time
            cache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    func removeCachedImage(for key: String) {
        // Remove from memory cache
        cache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let cacheURL = getCacheURL(for: key)
        try? fileManager.removeItem(at: cacheURL)
    }
    
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        let cacheDirectory = getCacheDirectory()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

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
    @State private var profileImage: Image?
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authVM = AuthViewModel()
    @State private var userData: [String: Any] = [:]
    @State private var isLoading = true
    @State private var showPasswordResetAlert = false
    @State private var passwordResetMessage: String?
    @StateObject private var colorBlindManager = ColorBlindModeManager()
    @State private var isUploadingProfile = false
    
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
                // Profile Image Section
                Section {
                    VStack(spacing: 12) {
                        if isUploadingProfile {
                            ProgressView()
                                .frame(width: 150, height: 150)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        } else if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(.gray)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change Photo")
                                .font(.subheadline)
                                .foregroundColor(primaryColor)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await uploadProfileImage(image: image)
                                }
                            }
                        }
                        
                        if profileImage != nil {
                            Button("Remove Photo") {
                                deleteProfileImage()
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)
                
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
    
    private func getCacheKey(for userId: String) -> String {
        "profile_image_\(userId)"
    }
    
    private func uploadProfileImage(image: UIImage) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isUploadingProfile = true
        
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                print("❌ Failed to convert image to data")
                isUploadingProfile = false
                return
            }
            
            // Create storage reference
            let imageRef = storage.child("profileImages/\(userId).jpg")
            
            // Upload image
            _ = try await imageRef.putDataAsync(imageData)
            
            // Get download URL
            let downloadURL = try await imageRef.downloadURL()
            
            // Update user document in Firestore
            try await db.collection("users").document(userId).updateData([
                "profileImageURL": downloadURL.absoluteString
            ])
            
            // Cache the image
            ImageCacheManager.shared.cacheImage(image, for: getCacheKey(for: userId))
            
            // Update local state
            DispatchQueue.main.async {
                self.profileImage = Image(uiImage: image)
                self.imageData = imageData
                self.isUploadingProfile = false
            }
            
            print("✅ Successfully uploaded profile image")
        } catch {
            print("❌ Error uploading profile image: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isUploadingProfile = false
            }
        }
    }
    
    private func loadProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Try loading from cache first
        if let cachedImage = ImageCacheManager.shared.getCachedImage(for: getCacheKey(for: userId)) {
            profileImage = Image(uiImage: cachedImage)
            imageData = cachedImage.jpegData(compressionQuality: 0.7)
            return
        }
        
        // If not in cache, load from Firestore/Storage
        db.collection("users").document(userId).getDocument { (document, error) in
            if let error = error {
                print("❌ Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document,
                  document.exists,
                  let data = document.data(),
                  let imageURL = data["profileImageURL"] as? String,
                  let url = URL(string: imageURL) else {
                print("❌ No profile image URL found")
                return
            }
            
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("❌ Error downloading image: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data,
                      let uiImage = UIImage(data: data) else {
                    print("❌ Invalid image data")
                    return
                }
                
                // Cache the downloaded image
                ImageCacheManager.shared.cacheImage(uiImage, for: getCacheKey(for: userId))
                
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                    self.imageData = data
                }
            }.resume()
        }
    }
    
    private func deleteProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let imageRef = storage.child("profileImages/\(userId).jpg")
        
        Task {
            do {
                // Delete from Storage
                try await imageRef.delete()
                
                // Update Firestore
                try await db.collection("users").document(userId).updateData([
                    "profileImageURL": FieldValue.delete()
                ])
                
                // Remove from cache
                ImageCacheManager.shared.removeCachedImage(for: getCacheKey(for: userId))
                
                // Clear local state
                DispatchQueue.main.async {
                    self.profileImage = nil
                    self.imageData = nil
                    self.selectedItem = nil
                }
                
                print("✅ Successfully deleted profile image")
            } catch {
                print("❌ Error deleting profile image: \(error.localizedDescription)")
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
