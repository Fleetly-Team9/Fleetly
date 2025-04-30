import SwiftUI
import PhotosUI

struct ProfileView: View {
    @State private var firstName = "John"
    @State private var lastName = "Doe"
    @State private var email = "john.doe@email.com"
    @State private var age = "30"
    @State private var gender = "Male"
    @State private var isEditing = false
    @State private var selectedImage: UIImage? = nil
    @State private var isPhotoPickerPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Image with Photo Picker
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .shadow(radius: 5)
                    .padding(.vertical, 20)
                    .onTapGesture {
                        isPhotoPickerPresented = true
                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .shadow(radius: 5)
                    .padding(.vertical, 20)
                    .onTapGesture {
                        isPhotoPickerPresented = true
                    }
            }
            
            // Name and Email
            VStack(spacing: 4) {
                Text("\(firstName) \(lastName)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(Color(hex: "444444"))
                Text(email)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 10)
            
            // Form for Details
            Form {
                // Personal Details Section
                Section(header: Text("Personal Details")
                    .font(.headline)
                    .foregroundColor(Color(hex: "444444"))) {
                    TextField("First Name", text: $firstName)
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .secondary)
                    TextField("Last Name", text: $lastName)
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .secondary)
                    TextField("Email", text: $email)
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .secondary)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Age", text: $age)
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .secondary)
                        .keyboardType(.numberPad)
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(!isEditing)
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        // Handle sign out logic here
                        print("Signed out")
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Maintenance Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        isEditing = false // Save and exit editing
                    } else {
                        isEditing = true // Start editing
                    }
                }
                .foregroundColor(isEditing ? .blue : .blue)
            }
        }
        .background(Color(hex: "F3F3F3").ignoresSafeArea())
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoPicker1(selectedImage: $selectedImage, isPresented: $isPhotoPickerPresented)
        }
    }
}

struct PhotoPicker1: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
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
        let parent: PhotoPicker1
        
        init(_ parent: PhotoPicker1) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                self.parent.isPresented = false
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                        self.parent.isPresented = false
                    }
                }
            }
            self.parent.isPresented = false
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}

