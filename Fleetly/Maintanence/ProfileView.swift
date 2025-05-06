import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Add a clear implementation of ProfileImageManager
class ProfileImageManager: ObservableObject {
    @Published var profileImage: UIImage?
    private let storage = Storage.storage().reference()
    private let db = Firestore.firestore()
    
    func saveImage(_ image: UIImage) {
        self.profileImage = image
        guard let userId = Auth.auth().currentUser?.uid,
              let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let imageRef = storage.child("profileImages/\(userId).jpg")
        
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
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
                    self.db.collection("users").document(userId).updateData([
                        "profileImageURL": downloadURL
                    ])
                }
            }
        }
        
        UserDefaults.standard.set(imageData, forKey: "profileImage")
    }
    
    func removeImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let imageRef = storage.child("profileImages/\(userId).jpg")
        
        imageRef.delete { error in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
                return
            }
            
            self.db.collection("users").document(userId).updateData([
                "profileImageURL": FieldValue.delete()
            ])
            
            UserDefaults.standard.removeObject(forKey: "profileImage")
            self.profileImage = nil
        }
    }
    
    func loadProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        if let savedData = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: savedData) {
            self.profileImage = uiImage
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
                            self.profileImage = uiImage
                            UserDefaults.standard.set(data, forKey: "profileImage")
                        }
                    }
                }.resume()
            }
        }
    }
}

struct ProfileView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileImageManager = ProfileImageManager()
    @State private var isPhotoPickerPresented = false
    @State private var showResetPasswordAlert = false
    @State private var passwordResetMessage: String?
    @State private var userData: [String: Any] = [:]
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Photo
                    ZStack(alignment: .bottomTrailing) {
                        if let image = profileImageManager.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .foregroundColor(.gray)
                        }
                        Button(action: {
                            isPhotoPickerPresented = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Color.blue))
                        }
                    }
                    .padding(.top, 10)

                    // Remove Photo Button
                    if profileImageManager.profileImage != nil {
                        Button(action: {
                            withAnimation {
                                profileImageManager.removeImage()
                            }
                        }) {
                            Text("Remove Photo")
                                .font(.system(.subheadline, design: .default, weight: .medium))
                                .foregroundColor(Color.pink)
                        }
                        .padding(.bottom, 10)
                    }

                    // Profile Details Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PROFILE DETAILS")
                            .font(.system(.caption, design: .default, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            let fullName = userData["name"] as? String ?? ""
                            let nameComponents = fullName.split(separator: " ").map { String($0) }
                            let firstName = nameComponents.first ?? ""
                            let lastName = nameComponents.dropFirst().joined(separator: " ")

                            HStack {
                                Text("First Name")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(firstName)
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)

                            HStack {
                                Text("Last Name")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(lastName)
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)

                            HStack {
                                Text("Phone Number")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(userData["phone"] as? String ?? "")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)

                            HStack {
                                Text("Email ID")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(userData["email"] as? String ?? "")
                                    .font(.system(.body, design: .default))
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )

                    // Reset Password Button
                    Button(action: {
                        sendPasswordResetEmail()
                    }) {
                        Text("Reset Password")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.05))
                            )
                    }
                    .alert(isPresented: $showResetPasswordAlert) {
                        Alert(
                            title: Text("Password Reset"),
                            message: Text(passwordResetMessage ?? "An error occurred"),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    // Sign Out Button
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
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.05))
                            )
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 15)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Maintenance Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $isPhotoPickerPresented) {
                ProfilePhotoPicker(profileImageManager: profileImageManager, isPresented: $isPhotoPickerPresented)
            }
            .onAppear {
                fetchUserData()
                profileImageManager.loadProfileImage()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
    
    private func sendPasswordResetEmail() {
        guard let email = userData["email"] as? String else {
            passwordResetMessage = "Email not found"
            showResetPasswordAlert = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                passwordResetMessage = "Failed to send reset email: \(error.localizedDescription)"
            } else {
                passwordResetMessage = "Password reset email sent to \(email)"
            }
            showResetPasswordAlert = true
        }
    }
}

// Renamed to avoid conflict with existing PhotoPicker
struct ProfilePhotoPicker: UIViewControllerRepresentable {
    var profileImageManager: ProfileImageManager
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfilePhotoPicker
        
        init(_ parent: ProfilePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let result = results.first else {
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        // Directly use the profileImageManager passed to the picker
                        self?.parent.profileImageManager.saveImage(image)
                    }
                }
            }
        }
    }
}


struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

//hellooo
