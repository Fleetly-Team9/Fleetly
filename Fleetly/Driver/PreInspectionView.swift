import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore

struct PreInspectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
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
    @State private var overallCheckStatus: String = "Raise Ticket"
    @State private var navigateToMapView = false
    @State private var navigateToTicketView = false
    @State private var fetchedTrip: Trip?
    @State private var errorMessage: String?
    @State private var expandedImageIndex: Int? = nil
    @State private var showTicketConfirmation = false
    @State private var isUploadingImages = false
    @State private var actualVehicleNumber: String = ""
    @State private var isSubmitting = false
    @State private var showAddTicketSheet = false
    @State private var ticketDescription = ""
    @State private var ticketPriority = "Medium"
    @State private var ticketType = "Maintenance"
    
    @ObservedObject var authVM: AuthViewModel
    let dropoffLocation: String
    let vehicleNumber: String
    let tripID: String
    let vehicleID: String
   
    
    private let db = Firestore.firestore()
    private let overallCheckOptions = ["Raise Ticket", "Verified"]
    private let priorityOptions = ["Low", "Medium", "High"]
    private let typeOptions = ["Maintenance", "Repair", "Inspection"]
    
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
    
    private func fetchVehicleNumber() {
        db.collection("vehicles").document(vehicleID).getDocument { document, error in
            if let document = document,
               let data = document.data(),
               let licensePlate = data["licensePlate"] as? String {
                DispatchQueue.main.async {
                    self.actualVehicleNumber = licensePlate
                }
            }
        }
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
    
    private var isAllChecked: Bool {
        return oilCheck && hornCheck && clutchCheck && airbagsCheck && physicalDamageCheck && tyrePressureCheck && brakesCheck && selectedImages.count == 4
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
                        Text("Start time")
                        Spacer()
                        Text(currentTimeString)
                    }
                    HStack {
                        Text("Vehicle Number")
                        Spacer()
                        Text(actualVehicleNumber.isEmpty ? "Loading..." : actualVehicleNumber)
                    }
                    HStack {
                        Text("Pickup Location")
                        Spacer()
                        Text(fetchedTrip?.startLocation ?? "Loading...")
                    }
                    HStack {
                        Text("Dropoff Location")
                        Spacer()
                        Text(fetchedTrip?.endLocation ?? dropoffLocation)
                    }
                }
                
                Section(header: Text("Car check")) {
                    Toggle(isOn: $oilCheck) {
                        Text("Oil")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: oilCheck) { _ in
                        if !isAllChecked {
                            overallCheckStatus = "Raise Ticket"
                        }
                    }
                    
                    Toggle(isOn: $hornCheck) {
                        Text("Horns")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: hornCheck) { _ in
                        if !isAllChecked {
                            overallCheckStatus = "Raise Ticket"
                        }
                    }
                    
                    Toggle(isOn: $clutchCheck) {
                        Text("Clutch")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: clutchCheck) { _ in
                        if !isAllChecked {
                            overallCheckStatus = "Raise Ticket"
                        }
                    }
                    
                    Toggle(isOn: $airbagsCheck) {
                        Text("Airbags")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: airbagsCheck) { _ in
                        if !isAllChecked {
                            overallCheckStatus = "Raise Ticket"
                        }
                    }
                    
                    Toggle(isOn: $physicalDamageCheck) {
                        Text("No Physical damage")
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .onChange(of: physicalDamageCheck) { _ in
                        if !isAllChecked {
                            overallCheckStatus = "Raise Ticket"
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $tyrePressureCheck) {
                            Text("Tyre Pressure").font(.headline)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        .onChange(of: tyrePressureCheck) { _ in
                            if !isAllChecked {
                                overallCheckStatus = "Raise Ticket"
                            }
                        }
                        
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
                        .toggleStyle(CheckboxToggleStyle())
                        .onChange(of: brakesCheck) { _ in
                            if !isAllChecked {
                                overallCheckStatus = "Raise Ticket"
                            }
                        }
                        
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
                
                Section(header: Text("Upload Images (4 Required)")) {
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
                            isUploadingImages = true
                            selectedImages.removeAll()
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data),
                                   let compressedData = FirebaseManager.shared.compressImage(uiImage),
                                   let compressedImage = UIImage(data: compressedData) {
                                    selectedImages.append(compressedImage)
                                }
                            }
                            isUploadingImages = false
                            if !isAllChecked {
                                overallCheckStatus = "Raise Ticket"
                            }
                        }
                    }
                    
                    if isUploadingImages {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading images...")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    if !selectedImages.isEmpty {
                        // 2x2 Grid Layout for Images
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ForEach(0..<min(2, selectedImages.count), id: \.self) { index in
                                    imageThumbView(for: selectedImages[index], index: index)
                                }
                            }
                            
                            if selectedImages.count > 2 {
                                HStack(spacing: 8) {
                                    ForEach(2..<min(4, selectedImages.count), id: \.self) { index in
                                        imageThumbView(for: selectedImages[index], index: index)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    HStack {
                        Text("Overall Check")
                        Spacer()
                        Picker("", selection: $overallCheckStatus) {
                            ForEach(overallCheckOptions, id: \.self) { option in
                                Text(option)
                                    .tag(option)
                                    .foregroundStyle(option == "Verified" ? Color.green : Color.red)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundStyle(overallCheckStatus == "Verified" ? Color.green : Color.red)
                        .disabled(!isAllChecked)
                    }
                }
            }
            .dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
            
            Button(action: {
                if overallCheckStatus == "Verified" {
                    submitInspectionAndProceed()
                } else {
                    showTicketConfirmation = true
                }
            }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    }
                    Text(isSubmitting ? "Recording Inspection..." : (overallCheckStatus == "Verified" ? "Ready for trip" : "Raise a Ticket?"))
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(overallCheckStatus == "Verified" ? .blue : .red)
            .padding(.horizontal)
            .padding(.top, 10)
            .disabled((overallCheckStatus == "Verified" && !isAllChecked) || isSubmitting)
        }
        .navigationTitle(Text("Pre Inspection"))
        .alert("Raise a Ticket", isPresented: $showTicketConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, I'm Sure", role: .destructive) {
                submitInspectionAndProceed()
            }
        } message: {
            Text("Are you sure you want to raise a ticket for this vehicle? This will mark the vehicle as having an issue that needs attention.")
        }
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
            fetchVehicleNumber()
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
        .background(
            NavigationLink(
                destination: NavigationMapView(
                    trip: fetchedTrip ?? Trip(
                        id: tripID,
                        driverId: authVM.user?.id ?? "",
                        vehicleId: vehicleID,
                        startLocation: "Unknown",
                        endLocation: dropoffLocation,
                        date: currentDateForFirestore,
                        time: currentTimeString,
                        startTime: Date(),
                        status: .assigned,
                        vehicleType: "Unknown",
                        passengers: nil,
                        loadWeight: nil
                    ),
                    vehicleID: vehicleID,
                    vehicleNumber: vehicleNumber,
                    authVM: authVM
                ),
                isActive: $navigateToMapView
            ) {
                EmptyView()
            }
        )
        .sheet(isPresented: $showAddTicketSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Ticket Details")) {
                        TextField("Description", text: $ticketDescription, axis: .vertical)
                            .lineLimit(3...6)
                        
                        Picker("Priority", selection: $ticketPriority) {
                            ForEach(priorityOptions, id: \.self) { priority in
                                Text(priority).tag(priority)
                            }
                        }
                        
                        Picker("Type", selection: $ticketType) {
                            ForEach(typeOptions, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                }
                .navigationTitle("Add Ticket")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showAddTicketSheet = false
                    },
                    trailing: Button("Submit") {
                        submitTicket()
                        showAddTicketSheet = false
                    }
                )
            }
        }
        .overlay {
            if let index = expandedImageIndex {
                ZStack {
                    Color.black.opacity(0.85)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            expandedImageIndex = nil
                        }
                    
                    VStack {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFit()
                            .padding()
                            .cornerRadius(12)
                        
                        Button(action: {
                            expandedImageIndex = nil
                        }) {
                            Text("Close")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }
    
    private func submitInspectionAndProceed() {
        guard let driverId = authVM.user?.id else {
            print("Driver ID is nil")
            return
        }
        
        isSubmitting = true
        let date = currentDateForFirestore
        
        // Immediately update UI state before Firebase operation
        let targetStatus = overallCheckStatus
        
        // For ticket raising, show the add ticket sheet
        if targetStatus == "Raise Ticket" {
            self.showAddTicketSheet = true
            isSubmitting = false
            return
        }
        
        FirebaseManager.shared.recordInspection(
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
            overallCheckStatus: overallCheckStatus,
            images: selectedImages,
            vehicleNumber: vehicleNumber,
            date: date,
            tripId: tripID,
            vehicleID: vehicleID,
            completion: { result in
                switch result {
                case .success:
                    print("Inspection recorded successfully")
                    fetchTrip { fetchResult in
                        switch fetchResult {
                        case .success(let trip):
                            self.fetchedTrip = trip
                            DispatchQueue.main.async {
                                if targetStatus == "Verified" {
                                    self.navigateToMapView = true
                                }
                            }
                        case .failure(let error):
                            self.errorMessage = "Failed to fetch trip: \(error.localizedDescription)"
                            print(self.errorMessage ?? "Unknown error")
                            isSubmitting = false
                        }
                    }
                case .failure(let error):
                    self.errorMessage = "Error recording inspection: \(error.localizedDescription)"
                    print(self.errorMessage ?? "Unknown error")
                    isSubmitting = false
                }
            }
        )
    }
    
    private func submitTicket() {
        guard let driverId = authVM.user?.id else { return }
        
        let ticket = [
            "description": ticketDescription,
            "priority": ticketPriority,
            "type": ticketType,
            "status": "Open",
            "createdBy": driverId,
            "vehicleId": vehicleID,
            "vehicleNumber": vehicleNumber,
            "createdAt": Date(),
            "tripId": tripID
        ] as [String: Any]
        
        db.collection("tickets").addDocument(data: ticket) { error in
            if let error = error {
                self.errorMessage = "Error creating ticket: \(error.localizedDescription)"
            } else {
                // Update trip status to cancelled
                self.db.collection("trips").document(self.tripID).updateData([
                    "status": "cancelled",
                    "cancelledAt": Date(),
                    "cancelledBy": driverId,
                    "cancellationReason": "Vehicle inspection failed"
                ]) { error in
                    if let error = error {
                        print("Error updating trip status: \(error.localizedDescription)")
                        self.errorMessage = "Failed to update trip status: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func imageThumbView(for image: UIImage, index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.5) : Color.gray, lineWidth: 1)
            )
            .onTapGesture {
                expandedImageIndex = index
            }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
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
