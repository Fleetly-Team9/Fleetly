
//
//  DriverProfileView 2.swift
//  Fleetly
//
//  Created by user@90 on 02/05/25.
//


import SwiftUI
import PhotosUI

struct DriverProfileView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var aadharImageSelection: PhotosPickerItem?
    @State private var licenseImageSelection: PhotosPickerItem?
    @State private var medicalInsuranceImageSelection: PhotosPickerItem?
    @State private var cachedAadharImage: UIImage?
    @State private var cachedLicenseImage: UIImage?
    @State private var cachedMedicalInsuranceImage: UIImage?
    @State private var isEditingMode: Bool = false
    @State private var showSignOutAlert: Bool = false
    @State private var selectedDocumentImage: UIImage?
    
    private let profileImageKey = "profileImage"
    private let aadharImageKey = "aadharImage"
    private let licenseImageKey = "licenseImage"
    private let medicalInsuranceImageKey = "medicalInsuranceImage"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                Color(UIColor.systemBackground) // System background for entire view
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) { // Smoother scrolling with hidden indicators
                    VStack(spacing: 0) { // Reduced spacing for smoother appearance
                        // Profile photo (no card)
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
                                        .foregroundColor(.blue)
                                }
                                .onChange(of: selectedProfileItem) { newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            DispatchQueue.main.async {
                                                profileImage = Image(uiImage: uiImage)
                                                // Save to UserDefaults
                                                if let data = uiImage.jpegData(compressionQuality: 0.8) {
                                                    UserDefaults.standard.set(data, forKey: profileImageKey)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                if profileImage != nil {
                                    Button(action: {
                                        profileImage = nil
                                        UserDefaults.standard.removeObject(forKey: profileImageKey)
                                    }) {
                                        Text("Remove Photo")
                                            .font(.subheadline)
                                            .foregroundColor(.red)
                                    }
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
                                documentDetailRow(
                                    title: "Aadhar Card",
                                    image: cachedAadharImage,
                                    selection: $aadharImageSelection,
                                    imageKey: aadharImageKey,
                                    onImageSelected: { newImage in
                                        cachedAadharImage = newImage
                                    }
                                )
                                
                                documentDetailRow(
                                    title: "Driving License",
                                    image: cachedLicenseImage,
                                    selection: $licenseImageSelection,
                                    imageKey: licenseImageKey,
                                    onImageSelected: { newImage in
                                        cachedLicenseImage = newImage
                                    }
                                )
                                
                                documentDetailRow(
                                    title: "Medical Insurance",
                                    image: cachedMedicalInsuranceImage,
                                    selection: $medicalInsuranceImageSelection,
                                    imageKey: medicalInsuranceImageKey,
                                    onImageSelected: { newImage in
                                        cachedMedicalInsuranceImage = newImage
                                    }
                                )
                            }
                            
                            // iOS native Sign Out Button in distinct container
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                Text("Sign Out")
                                    .foregroundColor(Color(.systemRed)) // iOS native red color
                                    .fontWeight(.regular)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.secondarySystemGroupedBackground)) // Same as cards for consistency
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
                
                // Simplified expanded document image view - no close button
                if let selectedImage = selectedDocumentImage {
                    ZStack {
                        // Full screen blur background
                        Rectangle()
                            .fill(Material.ultraThinMaterial) // iOS native blur effect
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedDocumentImage = nil // Dismiss on tap
                                }
                            }
                        
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit() // Maintain aspect ratio, fill screen height
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(20)
                            .contentShape(Rectangle()) // Ensures the whole area is tappable
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedDocumentImage = nil // Dismiss on tap
                                }
                            }
                    }
                    .transition(.opacity) // Smooth fade transition
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
                // Load profile image from UserDefaults
                if let data = UserDefaults.standard.data(forKey: profileImageKey),
                   let uiImage = UIImage(data: data) {
                    profileImage = Image(uiImage: uiImage)
                }
                // Load document images from UserDefaults
                if let data = UserDefaults.standard.data(forKey: aadharImageKey),
                   let uiImage = UIImage(data: data) {
                    cachedAadharImage = uiImage
                }
                if let data = UserDefaults.standard.data(forKey: licenseImageKey),
                   let uiImage = UIImage(data: data) {
                    cachedLicenseImage = uiImage
                }
                if let data = UserDefaults.standard.data(forKey: medicalInsuranceImageKey),
                   let uiImage = UIImage(data: data) {
                    cachedMedicalInsuranceImage = uiImage
                }
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
                    .fill(Color(UIColor.secondarySystemGroupedBackground)) // Card color that stands out from background
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
                .foregroundColor(Color(UIColor.label)) // Primary text color that adapts to theme
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(Color(UIColor.secondaryLabel)) // Secondary text color that adapts to theme
        }
    }
    
    private func documentDetailRow(
        title: String,
        image: UIImage?,
        selection: Binding<PhotosPickerItem?>,
        imageKey: String,
        onImageSelected: @escaping (UIImage?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if isEditingMode && image == nil {
                    PhotosPicker(selection: selection, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .onChange(of: selection.wrappedValue) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    onImageSelected(uiImage)
                                    // Save to UserDefaults
                                    if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                                        UserDefaults.standard.set(jpegData, forKey: imageKey)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            ZStack(alignment: .topTrailing) {
                if let docImage = image {
                    Image(uiImage: docImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(Color(UIColor.separator)) // iOS native separator color
                        )
                        .onTapGesture {
                            if !isEditingMode {
                                selectedDocumentImage = docImage
                            }
                        }
                } else {
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground)) // Secondary system background color
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Text("No document uploaded")
                                .foregroundColor(Color(UIColor.secondaryLabel)) // Secondary label color
                        )
                }
                
                // Smaller, simpler iOS-native style delete button
                if isEditingMode && image != nil {
                    Button {
                        // Direct deletion with animation
                        withAnimation {
                            onImageSelected(nil)
                            UserDefaults.standard.removeObject(forKey: imageKey)
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22)) // Smaller size
                            .foregroundColor(.red)
                    }
                    .offset(x: 5, y: -5) // Positioned in the corner
                    .padding(8)
                }
            }
        }
    }
}
