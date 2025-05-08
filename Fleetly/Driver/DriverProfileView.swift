//
//  DriverProfileView 2.swift
//  Fleetly
//
//  Created by user@90 on 02/05/25.
//


import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

struct DriverProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var aadharImage: UIImage?
    @State private var licenseImage: UIImage?
    @State private var medicalInsuranceImage: UIImage?
    @State private var medicalInsuranceSelection: PhotosPickerItem?
    @State private var isEditingMode: Bool = false
    @State private var showSignOutAlert: Bool = false
    @State private var selectedDocumentImage: UIImage?
    @State private var isLoadingAadhar = false
    @State private var isLoadingLicense = false
    @State private var isLoadingMedical = false
    @State private var isUploadingMedical = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Profile photo section
                        VStack(spacing: 12) {
                            if let profileImage = profileImage {
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
                            
                            if isEditingMode {
                                PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                                    Text("Change Photo")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Using custom UI instead of Form to ensure entire view scrolls
                        VStack(spacing: 20) {
                            // Personal Information Section
                            customSection(title: "Personal Information") {
                                if let user = authVM.user {
                                    customLabeledContent("Name", value: user.name)
                                    customLabeledContent("Email", value: user.email)
                                    customLabeledContent("Phone", value: user.phone)
                                    if let age = user.age {
                                        customLabeledContent("Age", value: "\(age)")
                                    }
                                    if let gender = user.gender {
                                        customLabeledContent("Gender", value: gender)
                                    }
                                }
                            }
                            
                            // Documents Details Section
                            customSection(title: "Documents Details") {
                                if let user = authVM.user {
                                    if let aadhar = user.aadharNumber {
                                        customLabeledContent("Aadhar Number", value: aadhar)
                                    }
                                    if let license = user.drivingLicenseNumber {
                                        customLabeledContent("License Number", value: license)
                                    }
                                }
                            }
                            
                            // Documents Section
                            customSection(title: "Documents") {
                                // Aadhar Card
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Aadhar Card")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    if let aadharImage = aadharImage {
                                        Image(uiImage: aadharImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(style: StrokeStyle(lineWidth: 1))
                                                    .foregroundColor(Color(UIColor.separator))
                                            )
                                            .onTapGesture {
                                                selectedDocumentImage = aadharImage
                                            }
                                    } else {
                                        Rectangle()
                                            .fill(Color(UIColor.secondarySystemBackground))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                Group {
                                                    if isLoadingAadhar {
                                                        VStack {
                                                            ProgressView()
                                                            Text("Loading Aadhar Card...")
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else {
                                                        Text("No Aadhar Card uploaded")
                                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                                    }
                                                }
                                            )
                                    }
                                }
                                
                                // Driving License
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Driving License")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    if let licenseImage = licenseImage {
                                        Image(uiImage: licenseImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(style: StrokeStyle(lineWidth: 1))
                                                    .foregroundColor(Color(UIColor.separator))
                                            )
                                            .onTapGesture {
                                                selectedDocumentImage = licenseImage
                                            }
                                    } else {
                                        Rectangle()
                                            .fill(Color(UIColor.secondarySystemBackground))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                Group {
                                                    if isLoadingLicense {
                                                        VStack {
                                                            ProgressView()
                                                            Text("Loading Driving License...")
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else {
                                                        Text("No Driving License uploaded")
                                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                                    }
                                                }
                                            )
                                    }
                                }
                                
                                // Medical Insurance
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Medical Insurance")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    if let medicalInsuranceImage = medicalInsuranceImage {
                                        Image(uiImage: medicalInsuranceImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(style: StrokeStyle(lineWidth: 1))
                                                    .foregroundColor(Color(UIColor.separator))
                                            )
                                            .onTapGesture {
                                                selectedDocumentImage = medicalInsuranceImage
                                            }
                                    } else {
                                        Rectangle()
                                            .fill(Color(UIColor.secondarySystemBackground))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                Group {
                                                    if isLoadingMedical {
                                                        VStack {
                                                            ProgressView()
                                                            Text("Loading Medical Insurance...")
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else if isUploadingMedical {
                                                        VStack {
                                                            ProgressView()
                                                            Text("Uploading...")
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else if isEditingMode {
                                                        PhotosPicker(selection: $medicalInsuranceSelection, matching: .images) {
                                                            VStack {
                                                                Image(systemName: "plus.circle.fill")
                                                                    .font(.system(size: 30))
                                                                    .foregroundColor(.blue)
                                                                Text("Upload Medical Insurance")
                                                                    .foregroundColor(.blue)
                                                            }
                                                        }
                                                        .onChange(of: medicalInsuranceSelection) { newItem in
                                                            Task {
                                                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                                                   let image = UIImage(data: data) {
                                                                    await uploadMedicalInsurance(image: image)
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        Text("No Medical Insurance uploaded")
                                                            .foregroundColor(Color(UIColor.secondaryLabel))
                                                    }
                                                }
                                            )
                                    }
                                }
                            }
                            
                            // Sign Out Button
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                Text("Sign Out")
                                    .foregroundColor(Color(.systemRed))
                                    .fontWeight(.regular)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                    )
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                        .padding(.bottom, 30)
                    }
                }
                .alert("Sign Out", isPresented: $showSignOutAlert) {
                    Button("Sign Out", role: .destructive) {
                        authVM.logout()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Do you want to sign out?")
                }
                
                // Document Preview Overlay
                if let selectedImage = selectedDocumentImage {
                    ZStack {
                        Rectangle()
                            .fill(Material.ultraThinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedDocumentImage = nil
                                }
                            }
                        
                        VStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(20)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedDocumentImage = nil
                                    }
                                }
                            
                            // Only show edit option for Medical Insurance
                            if selectedImage == medicalInsuranceImage && isEditingMode {
                                PhotosPicker(selection: $medicalInsuranceSelection, matching: .images) {
                                    Text("Change Medical Insurance")
                                        .foregroundColor(.blue)
                                        .padding()
                                }
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditingMode ? "Save" : "Edit") {
                        isEditingMode.toggle()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                loadDocuments()
            }
        }
    }
    
    private func getCacheDirectory() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    private func getCachedImage(for documentType: String) -> UIImage? {
        let cacheURL = getCacheDirectory().appendingPathComponent("\(authVM.user?.id ?? "")_\(documentType).jpg")
        if let data = try? Data(contentsOf: cacheURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    private func cacheImage(_ image: UIImage, for documentType: String) {
        let cacheURL = getCacheDirectory().appendingPathComponent("\(authVM.user?.id ?? "")_\(documentType).jpg")
        if let data = image.jpegData(compressionQuality: 0.7) {
            try? data.write(to: cacheURL)
        }
    }
    
    private func loadDocuments() {
        guard let user = authVM.user else {
            print("❌ loadDocuments: No user found in authVM")
            return
        }
        print("📱 loadDocuments: Starting to load documents for user: \(user.name)")
        
        // Load Aadhar Card
        if let aadharUrl = user.aadharDocUrl {
            print("📄 loadDocuments: Found Aadhar URL: \(aadharUrl)")
            
            // Try to load from cache first
            if let cachedImage = getCachedImage(for: "aadhar") {
                print("✅ loadDocuments: Loaded Aadhar from cache")
                self.aadharImage = cachedImage
            } else {
                isLoadingAadhar = true
                loadImage(from: aadharUrl) { image in
                    if let image = image {
                        print("✅ loadDocuments: Successfully loaded Aadhar image")
                        self.cacheImage(image, for: "aadhar")
                    } else {
                        print("❌ loadDocuments: Failed to load Aadhar image")
                    }
                    self.aadharImage = image
                    self.isLoadingAadhar = false
                }
            }
        } else {
            print("⚠️ loadDocuments: No Aadhar URL found for user")
        }
        
        // Load Driving License
        if let licenseUrl = user.licenseDocUrl {
            print("📄 loadDocuments: Found License URL: \(licenseUrl)")
            
            // Try to load from cache first
            if let cachedImage = getCachedImage(for: "license") {
                print("✅ loadDocuments: Loaded License from cache")
                self.licenseImage = cachedImage
            } else {
                isLoadingLicense = true
                loadImage(from: licenseUrl) { image in
                    if let image = image {
                        print("✅ loadDocuments: Successfully loaded License image")
                        self.cacheImage(image, for: "license")
                    } else {
                        print("❌ loadDocuments: Failed to load License image")
                    }
                    self.licenseImage = image
                    self.isLoadingLicense = false
                }
            }
        } else {
            print("⚠️ loadDocuments: No License URL found for user")
        }
        
        // Load Medical Insurance
        if let medicalUrl = user.medicalDocUrl {
            print("📄 loadDocuments: Found Medical Insurance URL: \(medicalUrl)")
            
            // Try to load from cache first
            if let cachedImage = getCachedImage(for: "medical") {
                print("✅ loadDocuments: Loaded Medical Insurance from cache")
                self.medicalInsuranceImage = cachedImage
            } else {
                isLoadingMedical = true
                loadImage(from: medicalUrl) { image in
                    if let image = image {
                        print("✅ loadDocuments: Successfully loaded Medical Insurance image")
                        self.cacheImage(image, for: "medical")
                    } else {
                        print("❌ loadDocuments: Failed to load Medical Insurance image")
                    }
                    self.medicalInsuranceImage = image
                    self.isLoadingMedical = false
                }
            }
        } else {
            print("⚠️ loadDocuments: No Medical Insurance URL found for user")
        }
    }
    
    private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        print("🔄 loadImage: Starting to load image from URL: \(urlString)")
        
        // Create a storage reference from the URL
        let storageRef = Storage.storage().reference(forURL: urlString)
        
        // Download the image data
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("❌ loadImage: Firebase Storage error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data else {
                print("❌ loadImage: No data received from Firebase Storage")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            print("📦 loadImage: Received data size: \(data.count) bytes")
            
            if let image = UIImage(data: data) {
                print("✅ loadImage: Successfully created image from data")
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("❌ loadImage: Failed to create image from data")
                // Try to print first few bytes of data for debugging
                let previewSize = min(data.count, 100)
                let previewData = data.prefix(previewSize)
                print("🔍 loadImage: Data preview (first \(previewSize) bytes): \(previewData.map { String(format: "%02x", $0) }.joined())")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func uploadMedicalInsurance(image: UIImage) async {
        guard let user = authVM.user else { return }
        isUploadingMedical = true
        
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                print("❌ Failed to convert image to data")
                isUploadingMedical = false
                return
            }
            
            // Create storage reference
            let storageRef = Storage.storage().reference()
            let medicalRef = storageRef.child("users/\(user.id)/medical.jpg")
            
            // Upload image
            _ = try await medicalRef.putDataAsync(imageData)
            
            // Get download URL
            let downloadURL = try await medicalRef.downloadURL()
            
            // Update user document in Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(user.id).updateData([
                "medicalDocUrl": downloadURL.absoluteString
            ])
            
            // Update local user object
            DispatchQueue.main.async {
                self.authVM.user?.medicalDocUrl = downloadURL.absoluteString
            }
            
            // Cache the uploaded image
            cacheImage(image, for: "medical")
            
            // Update local state
            DispatchQueue.main.async {
                self.medicalInsuranceImage = image
                self.isUploadingMedical = false
            }
            
            print("✅ Successfully uploaded medical insurance document")
        } catch {
            print("❌ Error uploading medical insurance: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isUploadingMedical = false
            }
        }
    }
    
    // Custom section to replace Form/Section
    private func customSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 1)
            )
            .padding(.horizontal)
        }
    }
    
    // Custom labeled content to replace LabeledContent
    private func customLabeledContent(
        _ label: String,
        value: String
    ) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Color(UIColor.label))
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}

struct DriverProfileView_Previews: PreviewProvider {
    static var previews: some View {
        DriverProfileView(authVM: AuthViewModel())
    }
}
