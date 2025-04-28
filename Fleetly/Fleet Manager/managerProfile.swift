import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

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
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 10)
                    }
                    .disabled(true) // Disable photo selection
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                                imageData = data
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Fleet Manager Details")) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Split name into first and last names
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
                    Button(action: {
                        sendPasswordResetEmail()
                    }) {
                        Text("Reset Password")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section {
                    Button(action: {
                        authVM.logout()
                        // Navigate to LoginView with the same authVM instance
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let loginView = LoginView(authVM: authVM)
                            let hostingController = UIHostingController(rootView: loginView)
                            window.rootViewController = hostingController
                            window.makeKeyAndVisible()
                        }
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.1))
                            )
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
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                fetchUserData()
                loadSavedImage()
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
    
    private func loadSavedImage() {
        if let savedData = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: savedData) {
            profileImage = Image(uiImage: uiImage)
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
