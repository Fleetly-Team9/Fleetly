import SwiftUI
import PhotosUI

// Add a clear implementation of ProfileImageManager
class ProfileImageManager: ObservableObject {
    @Published var profileImage: UIImage?
    
    // Add methods to save and load the image from UserDefaults or local storage
    func saveImage(_ image: UIImage) {
        self.profileImage = image
        // Here you could implement persistence to save the image to disk
        // saveImageToDocuments(image)
    }
    
    func removeImage() {
        self.profileImage = nil
        // Here you could implement code to remove the image from storage
        // removeImageFromDocuments()
    }
}

struct ProfileView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var profileImageManager = ProfileImageManager()
    @State private var isPhotoPickerPresented = false
    @State private var showResetPasswordAlert = false
    @Environment(\.dismiss) var dismiss

    // Static profile details (not editable)
    private let firstName = "John"
    private let lastName = "Doe"
    private let phoneNumber = "9603839868"
    private let email = "john.doe@email.com"

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
                            Text(phoneNumber)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)

                        HStack {
                            Text("Email ID")
                                .font(.system(.body, design: .default))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(email)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)
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
                        showResetPasswordAlert = true
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
                            message: Text("Password reset email sent to \(email)"),
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
            .navigationBarBackButtonHidden(true)
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
        }
        .presentationDetents([.large])
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
