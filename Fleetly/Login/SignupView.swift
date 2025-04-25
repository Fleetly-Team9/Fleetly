import SwiftUI
import PhotosUI

struct SignupView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var age = ""
    @State private var aadhar = ""
    @State private var license = ""
    @State private var disability = ""
    @State private var aadharPhotoItem: PhotosPickerItem?
    @State private var licensePhotoItem: PhotosPickerItem?
    @State private var error: String?
    @Environment(\.dismiss) var dismiss
    @State private var isAgeValid: Bool = true
    @State private var isLoading = false
    @State private var showOTPVerification = false
       @State private var showWaitingApproval = false

    let genders = ["Male", "Female"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.1), .white], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if showWaitingApproval {
                           waitingApprovalView
                       } else if showOTPVerification {
                           SignupOTPView(authVM: authVM, onVerificationComplete: { success in
                               if success {
                                   showOTPVerification = false
                                   showWaitingApproval = true
                               }
                           })
                       } else {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue)

                            Text("Driver Sign Up")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                        }
                        .padding(.top, 40)

                        VStack(spacing: 16) {
                            HStack {
                                TextField("First Name", text: $firstName)
                                    .textFieldStyle(.plain)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                                TextField("Last Name", text: $lastName)
                                    .textFieldStyle(.plain)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }

                            Menu {
                                ForEach(genders, id: \.self) { option in
                                    Button(action: { gender = option }) {
                                        Text(option)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(gender.isEmpty ? "Select a gender" : gender)
                                        .foregroundColor(gender.isEmpty ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .frame(height: 50)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            }

                            TextField("Contact Number", text: $phone)
                                .textFieldStyle(.plain)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: phone) { phone = String(phone.prefix(10)).filter { $0.isNumber } }

                            TextField("Email", text: $email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                            TextField("Age (must be 18 or above)", text: $age)
                                .textFieldStyle(.plain)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isAgeValid ? Color.clear : Color.red, lineWidth: 1.5)
                                        )
                                )
                                .onChange(of: age) {
                                    age = String(age.prefix(3).filter { $0.isNumber })
                                    if let val = Int(age) {
                                        if val > 120 { age = "120" }
                                        isAgeValid = val >= 18
                                    } else {
                                        isAgeValid = false
                                    }
                                }

                            TextField("Aadhar Number (xxxx-xxxx-xxxx)", text: $aadhar)
                                .textFieldStyle(.plain)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: aadhar) {
                                    let digits = aadhar.filter { $0.isNumber }
                                    let formatted = stride(from: 0, to: digits.count, by: 4).map {
                                        Array(digits)[$0..<min($0+4, digits.count)]
                                    }.map { String($0) }.joined(separator: "-")
                                    aadhar = formatted.prefix(14).description
                                }

                            TextField("License Number (AA-RR-YYYY-NNNNNNN)", text: $license)
                                .textFieldStyle(.plain)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.characters)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .onChange(of: license) {
                                    var cleaned = license.replacingOccurrences(of: "[^A-Za-z0-9-]", with: "", options: .regularExpression)
                                    let letters = cleaned.filter { $0.isLetter }.uppercased()
                                    let digits = cleaned.filter { $0.isNumber }
                                    var formattedParts: [String] = []

                                    if letters.count >= 1 { formattedParts.append(String(letters.prefix(2))) }
                                    if digits.count >= 1 { formattedParts.append(String(digits.prefix(2))) }
                                    if digits.count >= 3 { formattedParts.append(String(digits.dropFirst(2).prefix(4))) }
                                    if digits.count >= 7 { formattedParts.append(String(digits.dropFirst(6).prefix(3))) }
                                    if digits.count >= 10 { formattedParts.append(String(digits.dropFirst(9).prefix(4))) }

                                    let formatted = formattedParts.joined(separator: "-")
                                    license = formatted.prefix(19).description
                                }// In SignupView.swift
                               
                        }
                        .padding(.horizontal, 24)

                        HStack(spacing: 16) {
                            PhotosPicker(
                                selection: $aadharPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label(aadharPhotoItem != nil ? "Aadhar Uploaded" : "Aadhar Proof", systemImage: "doc.text.fill")
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.blue)
                            }

                            PhotosPicker(
                                selection: $licensePhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label(licensePhotoItem != nil ? "License Uploaded" : "License Proof", systemImage: "doc.badge.plus")
                                    .font(.body)
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 24)

                        if let error = error {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        } else {
                            Button(action: signup) {
                                Text("Sign Up")
                                    .font(.system(.headline, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(isFormValid ? .blue : .gray)
                            .padding(.horizontal, 24)
                            .disabled(!isFormValid)
                        }

                        Spacer()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showOTPVerification) {
            SignupOTPView(authVM: authVM) { success in
                if success {
                    showOTPVerification = false
                    showWaitingApproval = true
                }
            }
        }
    }
    private var waitingApprovalView: some View {
            VStack(spacing: 24) {
                Image(systemName: "clock.badge.checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundStyle(.blue)

                Text("Waiting for Approval")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Your registration is complete! We've sent your details to our manager for verification.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Got it")
                {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding()
        }
    

    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !phone.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !aadhar.isEmpty &&
        !license.isEmpty &&
        !gender.isEmpty &&
        isAgeValid
    }

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

    private func signup() {
        isLoading = true
        authVM.signupDriver(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            age: Int(age) ?? 0,
            disability: disability,
            phone: phone,
            email: email,
            password: password,
            aadharNumber: aadhar,
            licenseNumber: license,
            aadharPhotoItem: aadharPhotoItem,
            licensePhotoItem: licensePhotoItem
        ) { err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    self.error = err
                } else {
                    showOTPVerification = true                }
            }
        }
    }
}
