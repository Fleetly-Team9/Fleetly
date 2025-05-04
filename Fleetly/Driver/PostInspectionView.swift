import Foundation
import MapKit
import SwiftUI
import PhotosUI
import FirebaseFirestore
//Working
/*struct PostInspectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var tyrePressureRemarks: String = ""
    @State private var brakeRemarks: String = ""
    @State private var oilCheck = false
    @State private var hornCheck = false
    @State private var clutchCheck = false
    @State private var airbagsCheck = false
    @State private var physicalDamageCheck = false
    @State private var tyrePressureCheck = false
    @State private var brakesCheck = false
    @State private var indicatorsCheck = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var overallCheckStatus: String = "Ticket raised"
    @State private var fetchedTrip: Trip?
    @State private var errorMessage: String?
    @State private var inspectionCompleted = false
    @State private var mileage: Double? = nil // Changed to Double?
  
    @ObservedObject var authVM: AuthViewModel
    let dropoffLocation: String
    let vehicleNumber: String
    let tripID: String
    let vehicleID: String
    
    private let db = Firestore.firestore()
    private let overallCheckOptions = ["Ticket raised", "Verified"]
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private var currentDateForFirestore: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private func fetchTrip(completion: @escaping (Result<Trip, Error>) -> Void) {
        db.collection("trips").document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
                return
            }
            if let trip = Trip.from(document: document) {
                completion(.success(trip))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse trip"])))
            }
        }
    }
    
    // Computed property to bind TextField (String) to mileage (Double?)
    private var mileageText: Binding<String> {
        Binding<String>(
            get: {
                if let mileageValue = mileage {
                    return String(mileageValue)
                } else {
                    return ""
                }
            },
            set: { newValue in
                // Filter to allow only numbers and one decimal point
                let filtered = newValue.filter { char in
                    char.isNumber || char == "."
                }
                
                // Handle multiple decimal points
                let components = filtered.components(separatedBy: ".")
                let validatedString: String
                if components.count > 2 {
                    validatedString = components[0] + "." + components[1]
                } else if filtered.starts(with: ".") {
                    validatedString = "0" + filtered
                } else {
                    validatedString = filtered
                }
                
                // Convert to Double or set to nil if invalid
                if validatedString.isEmpty {
                    mileage = nil
                } else if let doubleValue = Double(validatedString) {
                    mileage = doubleValue
                } else {
                    mileage = nil
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Trip Details")) {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(currentDateString)
                    }
                    HStack {
                        Text("End time")
                        Spacer()
                        Text(currentTimeString)
                    }
                    HStack {
                        Text("Vehicle Number")
                        Spacer()
                        Text(vehicleNumber)
                    }
                    HStack {
                        Text("Pickup Location")
                        Spacer()
                        Text(fetchedTrip?.startLocation ?? "Loading...")
                    }
                    HStack {
                        Text("Dropoff Location")
                        Spacer()
                        Text(dropoffLocation)
                    }
                }
                
                Section(header: Text("Car check")) {
                    Toggle(isOn: $oilCheck) {
                        Text("Oil")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $hornCheck) {
                        Text("Horns")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $clutchCheck) {
                        Text("Clutch")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $airbagsCheck) {
                        Text("Airbags")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $physicalDamageCheck) {
                        Text("No Physical damage")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    // Mileage Field with KM Card
                    HStack(alignment: .center, spacing: 8) {
                        Text("Mileage")
                        Spacer()
                        ZStack {
                            HStack(spacing: 0) {
                                TextField("km", text: mileageText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                                    .frame(width: 100)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.leading)
                                    .padding(.trailing, -1)
                                
                                Text("KM")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(UIColor.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(width: 150)
                    }
                    .padding(.top, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $tyrePressureCheck) {
                            Text("Tyre Pressure").font(.headline)
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remarks:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Examples: All tyres at 35 PSI, Front-left slightly low, No visible damage",
                                     text: $tyrePressureRemarks,
                                     axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $brakesCheck) {
                            Text("Brakes").font(.headline)
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remarks:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Examples: Brake pads 50% worn, Fluid level normal, No unusual noises",
                                     text: $brakeRemarks,
                                     axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 5,
                        selectionBehavior: .ordered,
                        matching: .images
                    ) {
                        Label("Add 4 images", systemImage: "photo.on.rectangle.angled")
                            .foregroundStyle(Color.blue)
                    }
                    .onChange(of: selectedItems) { newItems in
                        Task {
                            selectedImages.removeAll()
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImages.append(uiImage)
                                }
                            }
                        }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Overall Check")
                        if overallCheckStatus == "Verified" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .padding(.leading, 5)
                        }
                        Spacer()
                        Picker("", selection: $overallCheckStatus) {
                            ForEach(overallCheckOptions, id: \.self) { option in
                                Text(option)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(overallCheckStatus == "Verified" ? Color.green : Color.red)
                    }
                }
            }
            
            Button(action: {
                guard let driverId = authVM.user?.id else {
                    print("Driver ID is nil")
                    return
                }
                
                let date = currentDateForFirestore
                
                FirebaseManager.shared.recordPostInspection(
                    driverId: driverId,
                    tyrePressureRemarks: tyrePressureRemarks,
                    brakeRemarks: brakeRemarks,
                    oilCheck: oilCheck,
                    hornCheck: hornCheck,
                    clutchCheck: clutchCheck,
                    airbagsCheck: airbagsCheck,
                    physicalDamageCheck: physicalDamageCheck,
                    tyrePressureCheck: tyrePressureCheck,
                    brakesCheck: brakesCheck,
                    indicatorsCheck: indicatorsCheck,
                    mileage: mileage,
                    overallCheckStatus: overallCheckStatus,
                    images: selectedImages,
                    vehicleNumber: vehicleNumber,
                    date: date,
                    tripId: tripID,
                    vehicleID: vehicleID,
                    completion: { result in
                        switch result {
                        case .success:
                            print("Post-inspection recorded successfully")
                            inspectionCompleted = true
                        case .failure(let error):
                            errorMessage = "Error recording post-inspection: \(error.localizedDescription)"
                            print(errorMessage ?? "Unknown error")
                        }
                    }
                )
            }) {
                Text("Complete Inspection")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal)
            .padding(.top, 10)
            .disabled(selectedImages.count != 4)
        }
        .navigationTitle(Text("Post Inspection"))
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: inspectionCompleted) { completed in
            if completed {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onAppear {
            fetchTrip { result in
                switch result {
                case .success(let trip):
                    self.fetchedTrip = trip
                case .failure(let error):
                    self.errorMessage = "Failed to fetch trip: \(error.localizedDescription)"
                    print(self.errorMessage ?? "Unknown error")
                }
            }
        }
    }
}

struct CheckboxToggleStyle2: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
*/


//2tab bars
/*struct PostInspectionView: View {
    @State private var tyrePressureRemarks: String = ""
    @State private var brakeRemarks: String = ""
    @State private var oilCheck = false
    @State private var hornCheck = false
    @State private var clutchCheck = false
    @State private var airbagsCheck = false
    @State private var physicalDamageCheck = false
    @State private var tyrePressureCheck = false
    @State private var brakesCheck = false
    @State private var indicatorsCheck = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var overallCheckStatus: String = "Ticket raised"
    @State private var fetchedTrip: Trip?
    @State private var errorMessage: String?
    @State private var inspectionCompleted = false
    @State private var mileage: Double? = nil
  
    @ObservedObject var authVM: AuthViewModel
    let dropoffLocation: String
    let vehicleNumber: String
    let tripID: String
    let vehicleID: String
    let onComplete: () -> Void // Add onComplete closure to reset navigation
    
    private let db = Firestore.firestore()
    private let overallCheckOptions = ["Ticket raised", "Verified"]
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private var currentDateForFirestore: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private func fetchTrip(completion: @escaping (Result<Trip, Error>) -> Void) {
        db.collection("trips").document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
                return
            }
            if let trip = Trip.from(document: document) {
                completion(.success(trip))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse trip"])))
            }
        }
    }
    
    private var mileageText: Binding<String> {
        Binding<String>(
            get: {
                if let mileageValue = mileage {
                    return String(mileageValue)
                } else {
                    return ""
                }
            },
            set: { newValue in
                let filtered = newValue.filter { char in
                    char.isNumber || char == "."
                }
                
                let components = filtered.components(separatedBy: ".")
                let validatedString: String
                if components.count > 2 {
                    validatedString = components[0] + "." + components[1]
                } else if filtered.starts(with: ".") {
                    validatedString = "0" + filtered
                } else {
                    validatedString = filtered
                }
                
                if validatedString.isEmpty {
                    mileage = nil
                } else if let doubleValue = Double(validatedString) {
                    mileage = doubleValue
                } else {
                    mileage = nil
                }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Form {
                    Section(header: Text("Trip Details")) {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(currentDateString)
                        }
                        HStack {
                            Text("End time")
                            Spacer()
                            Text(currentTimeString)
                        }
                        HStack {
                            Text("Vehicle Number")
                            Spacer()
                            Text(vehicleNumber)
                        }
                        HStack {
                            Text("Pickup Location")
                            Spacer()
                            Text(fetchedTrip?.startLocation ?? "Loading...")
                        }
                        HStack {
                            Text("Dropoff Location")
                            Spacer()
                            Text(dropoffLocation)
                        }
                    }
                    
                    Section(header: Text("Car check")) {
                        Toggle(isOn: $oilCheck) {
                            Text("Oil")
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        Toggle(isOn: $hornCheck) {
                            Text("Horns")
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        Toggle(isOn: $clutchCheck) {
                            Text("Clutch")
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        Toggle(isOn: $airbagsCheck) {
                            Text("Airbags")
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        Toggle(isOn: $physicalDamageCheck) {
                            Text("No Physical damage")
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text("Mileage")
                            Spacer()
                            ZStack {
                                HStack(spacing: 0) {
                                    TextField("km", text: mileageText)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.caption)
                                        .frame(width: 100)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.leading)
                                        .padding(.trailing, -1)
                                    
                                    Text("KM")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color(UIColor.systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                                .background(Color(UIColor.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .frame(width: 150)
                        }
                        .padding(.top, 8)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $tyrePressureCheck) {
                                Text("Tyre Pressure").font(.headline)
                            }
                            .toggleStyle(CheckboxToggleStyle2())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remarks:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Examples: All tyres at 35 PSI, Front-left slightly low, No visible damage",
                                         text: $tyrePressureRemarks,
                                         axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $brakesCheck) {
                                Text("Brakes").font(.headline)
                            }
                            .toggleStyle(CheckboxToggleStyle2())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remarks:")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                TextField("Examples: Brake pads 50% worn, Fluid level normal, No unusual noises",
                                         text: $brakeRemarks,
                                         axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 5,
                            selectionBehavior: .ordered,
                            matching: .images
                        ) {
                            Label("Add 4 images", systemImage: "photo.on.rectangle.angled")
                                .foregroundStyle(Color.blue)
                        }
                        .onChange(of: selectedItems) { newItems in
                            Task {
                                selectedImages.removeAll()
                                for item in newItems {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        selectedImages.append(uiImage)
                                    }
                                }
                            }
                        }
                        
                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(selectedImages, id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Overall Check")
                            if overallCheckStatus == "Verified" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                                    .padding(.leading, 5)
                            }
                            Spacer()
                            Picker("", selection: $overallCheckStatus) {
                                ForEach(overallCheckOptions, id: \.self) { option in
                                    Text(option)
                                        .tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundStyle(overallCheckStatus == "Verified" ? Color.green : Color.red)
                        }
                    }
                }
                
                Button(action: {
                    guard let driverId = authVM.user?.id else {
                        print("Driver ID is nil")
                        return
                    }
                    
                    let date = currentDateForFirestore
                    
                    FirebaseManager.shared.recordPostInspection(
                        driverId: driverId,
                        tyrePressureRemarks: tyrePressureRemarks,
                        brakeRemarks: brakeRemarks,
                        oilCheck: oilCheck,
                        hornCheck: hornCheck,
                        clutchCheck: clutchCheck,
                        airbagsCheck: airbagsCheck,
                        physicalDamageCheck: physicalDamageCheck,
                        tyrePressureCheck: tyrePressureCheck,
                        brakesCheck: brakesCheck,
                        indicatorsCheck: indicatorsCheck,
                        mileage: mileage,
                        overallCheckStatus: overallCheckStatus,
                        images: selectedImages,
                        vehicleNumber: vehicleNumber,
                        date: date,
                        tripId: tripID,
                        vehicleID: vehicleID,
                        completion: { result in
                            switch result {
                            case .success:
                                print("Post-inspection recorded successfully")
                                inspectionCompleted = true
                                onComplete() // Call onComplete to reset navigation
                            case .failure(let error):
                                errorMessage = "Error recording post-inspection: \(error.localizedDescription)"
                                print(errorMessage ?? "Unknown error")
                            }
                        }
                    )
                }) {
                    Text("Complete Inspection")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 10)
                .disabled(selectedImages.count != 4)
            }
            .navigationTitle(Text("Post Inspection"))
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                fetchTrip { result in
                    switch result {
                    case .success(let trip):
                        self.fetchedTrip = trip
                    case .failure(let error):
                        self.errorMessage = "Failed to fetch trip: \(error.localizedDescription)"
                        print(self.errorMessage ?? "Unknown error")
                    }
                }
            }
            // Navigate to MainView when inspection is completed
            .navigationDestination(isPresented: $inspectionCompleted) {
                MainView(authVM: authVM)
                    .navigationBarBackButtonHidden(true) // Hide back button to prevent going back to PostInspectionView
            }
        }
    }
}

struct CheckboxToggleStyle2: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
*/

// MARK: - PostInspectionView
struct PostInspectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var tyrePressureRemarks: String = ""
    @State private var brakeRemarks: String = ""
    @State private var oilCheck = false
    @State private var hornCheck = false
    @State private var clutchCheck = false
    @State private var airbagsCheck = false
    @State private var physicalDamageCheck = false
    @State private var tyrePressureCheck = false
    @State private var brakesCheck = false
    @State private var indicatorsCheck = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var overallCheckStatus: String = "Ticket raised"
    @State private var fetchedTrip: Trip?
    @State private var errorMessage: String?
    @State private var inspectionCompleted = false
    @State private var mileage: Double? = nil
    
    @ObservedObject var authVM: AuthViewModel
    let dropoffLocation: String
    let vehicleNumber: String
    let tripID: String
    let vehicleID: String
    let onComplete: () -> Void
    
    private let db = Firestore.firestore()
    private let overallCheckOptions = ["Ticket raised", "Verified"]
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private var currentDateForFirestore: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private func fetchTrip(completion: @escaping (Result<Trip, Error>) -> Void) {
        db.collection("trips").document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
                return
            }
            if let trip = Trip.from(document: document) {
                completion(.success(trip))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse trip"])))
            }
        }
    }
    
    private var mileageText: Binding<String> {
        Binding<String>(
            get: {
                if let mileageValue = mileage {
                    return String(mileageValue)
                } else {
                    return ""
                }
            },
            set: { newValue in
                let filtered = newValue.filter { char in
                    char.isNumber || char == "."
                }
                
                let components = filtered.components(separatedBy: ".")
                let validatedString: String
                if components.count > 2 {
                    validatedString = components[0] + "." + components[1]
                } else if filtered.starts(with: ".") {
                    validatedString = "0" + filtered
                } else {
                    validatedString = filtered
                }
                
                if validatedString.isEmpty {
                    mileage = nil
                } else if let doubleValue = Double(validatedString) {
                    mileage = doubleValue
                } else {
                    mileage = nil
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Trip Details")) {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(currentDateString)
                    }
                    HStack {
                        Text("End time")
                        Spacer()
                        Text(currentTimeString)
                    }
                    HStack {
                        Text("Vehicle Number")
                        Spacer()
                        Text(vehicleNumber)
                    }
                    HStack {
                        Text("Pickup Location")
                        Spacer()
                        Text(fetchedTrip?.startLocation ?? "Loading...")
                    }
                    HStack {
                        Text("Dropoff Location")
                        Spacer()
                        Text(dropoffLocation)
                    }
                }
                
                Section(header: Text("Car check")) {
                    Toggle(isOn: $oilCheck) {
                        Text("Oil")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $hornCheck) {
                        Text("Horns")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $clutchCheck) {
                        Text("Clutch")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $airbagsCheck) {
                        Text("Airbags")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    Toggle(isOn: $physicalDamageCheck) {
                        Text("No Physical damage")
                    }
                    .toggleStyle(CheckboxToggleStyle2())
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text("Mileage")
                        Spacer()
                        ZStack {
                            HStack(spacing: 0) {
                                TextField("km", text: mileageText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.caption)
                                    .frame(width: 100)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.leading)
                                    .padding(.trailing, -1)
                                
                                Text("KM")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(UIColor.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .frame(width: 150)
                    }
                    .padding(.top, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $tyrePressureCheck) {
                            Text("Tyre Pressure").font(.headline)
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remarks:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Examples: All tyres at 35 PSI, Front-left slightly low, No visible damage",
                                     text: $tyrePressureRemarks,
                                     axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $brakesCheck) {
                            Text("Brakes").font(.headline)
                        }
                        .toggleStyle(CheckboxToggleStyle2())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remarks:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Examples: Brake pads 50% worn, Fluid level normal, No unusual noises",
                                     text: $brakeRemarks,
                                     axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 5,
                        selectionBehavior: .ordered,
                        matching: .images
                    ) {
                        Label("Add 4 images", systemImage: "photo.on.rectangle.angled")
                            .foregroundStyle(Color.blue)
                    }
                    .onChange(of: selectedItems) { newItems in
                        Task {
                            selectedImages.removeAll()
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImages.append(uiImage)
                                }
                            }
                        }
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(selectedImages, id: \.self) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Overall Check")
                        if overallCheckStatus == "Verified" {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .padding(.leading, 5)
                        }
                        Spacer()
                        Picker("", selection: $overallCheckStatus) {
                            ForEach(overallCheckOptions, id: \.self) { option in
                                Text(option)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(overallCheckStatus == "Verified" ? Color.green : Color.red)
                    }
                }
            }
            
            Button(action: {
                guard let driverId = authVM.user?.id else {
                    print("Driver ID is nil")
                    return
                }
                
                let date = currentDateForFirestore
                
                FirebaseManager.shared.recordPostInspection(
                    driverId: driverId,
                    tyrePressureRemarks: tyrePressureRemarks,
                    brakeRemarks: brakeRemarks,
                    oilCheck: oilCheck,
                    hornCheck: hornCheck,
                    clutchCheck: clutchCheck,
                    airbagsCheck: airbagsCheck,
                    physicalDamageCheck: physicalDamageCheck,
                    tyrePressureCheck: tyrePressureCheck,
                    brakesCheck: brakesCheck,
                    indicatorsCheck: indicatorsCheck,
                    mileage: mileage,
                    overallCheckStatus: overallCheckStatus,
                    images: selectedImages,
                    vehicleNumber: vehicleNumber,
                    date: date,
                    tripId: tripID,
                    vehicleID: vehicleID,
                    completion: { result in
                        switch result {
                        case .success:
                            print("Post-inspection recorded successfully")
                            inspectionCompleted = true
                            onComplete()
                            dismiss()
                        case .failure(let error):
                            errorMessage = "Error recording post-inspection: \(error.localizedDescription)"
                            print(errorMessage ?? "Unknown error")
                        }
                    }
                )
            }) {
                Text("Complete Inspection")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal)
            .padding(.top, 10)
            .disabled(selectedImages.count != 4)
        }
        .navigationTitle(Text("Post Inspection"))
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            fetchTrip { result in
                switch result {
                case .success(let trip):
                    self.fetchedTrip = trip
                case .failure(let error):
                    self.errorMessage = "Failed to fetch trip: \(error.localizedDescription)"
                    print(self.errorMessage ?? "Unknown error")
                }
            }
        }
    }
}

// MARK: - CheckboxToggleStyle2
struct CheckboxToggleStyle2: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(configuration.isOn ? .green : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Extensions
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], latitudinalMetersPadding: CLLocationDistance, longitudinalMetersPadding: CLLocationDistance) {
        guard !coordinates.isEmpty else {
            self.init(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            return
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) + (latitudinalMetersPadding / 111320.0),
            longitudeDelta: (maxLon - minLon) + (longitudinalMetersPadding / (111320.0 * cos(center.latitude * .pi / 180.0)))
        )
        
        self.init(center: center, span: span)
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        coords.withUnsafeMutableBufferPointer { ptr in
            getCoordinates(ptr.baseAddress!, range: NSRange(location: 0, length: pointCount))
        }
        return coords
    }
}
