import SwiftUI
import PhotosUI
import AVFoundation

struct AddTicketView: View {
    @State private var selectedIssueCategory: IssueCategory = .tripIssue
    @State private var selectedTrip: Trip?
    @State private var selectedVehicle: Vehicle?
    @State private var issueType: IssueType = .mechanical
    @State private var priority: Priority = .low
    @State private var description: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingCamera = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticketManager: TicketManager
    
    enum IssueCategory: String, CaseIterable, Identifiable {
        case tripIssue = "Trip Issue"
        case vehicleIssue = "Vehicle Issue"
        var id: String { rawValue }
    }
    
    enum IssueType: String, CaseIterable, Identifiable {
        case mechanical = "Mechanical"
        case electrical = "Electrical"
        case bodyDamage = "Body Damage"
        case other = "Other"
        var id: String { rawValue }
    }
    
    enum Priority: String, CaseIterable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle"
            case .medium: return "minus.circle"
            case .high: return "exclamationmark.circle"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Issue Category Selection with Segmented Control
                Section(header: Text("Issue Category")) {
                    Picker("", selection: $selectedIssueCategory) {
                        ForEach(IssueCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                
                // Trip/Vehicle Selection
                Section(header: Text(selectedIssueCategory == .tripIssue ? "Trip Details" : "Vehicle Details")) {
                    if selectedIssueCategory == .tripIssue {
                        TripSelectionView(selectedTrip: $selectedTrip)
                    } else {
                        VehicleSelectionView(selectedVehicle: $selectedVehicle)
                    }
                }
                
                // Issue Classification
                Section(header: Text("Issue Classification")) {
                    HStack {
                        Text("Issue Type")
                        Spacer()
                        Menu {
                            ForEach(IssueType.allCases) { type in
                                Button {
                                    issueType = type
                                } label: {
                                    Text(type.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(issueType.rawValue)
                                    .foregroundStyle(.blue)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Priority")
                        Spacer()
                        Menu {
                            ForEach(Priority.allCases) { priorityOption in
                                Button {
                                    priority = priorityOption
                                } label: {
                                    Label {
                                        Text(priorityOption.rawValue)
                                    } icon: {
                                        Image(systemName: priorityOption.icon)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Label {
                                    Text(priority.rawValue)
                                } icon: {
                                    Image(systemName: priority.icon)
                                }
                                .foregroundStyle(priority.color)
                            }
                        }
                    }
                }
                
                // Description Input
                Section(header: Text("Description")) {
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Describe the issue in detail...")
                                .foregroundStyle(.gray)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .background(Color.clear)
                    }
                    .textInputAutocapitalization(.sentences)
                }
                
                // Photo Attachments
                Section(header: Text("Photos")) {
                    VStack(alignment: .leading) {
                        if !photoImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photoImages.indices, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: photoImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button(action: {
                                                photoImages.remove(at: index)
                                                selectedPhotos.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                            }
                                            .offset(x: 6, y: -6)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                        HStack {
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                Label("Photo", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .controlSize(.large)
                            
                            Button {
                                showingCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .controlSize(.large)
                        }
                        
                        Text("Add up to 5 photos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Submit Button Section
                Section {
                    Button(action: {
                        validateAndSubmit()
                    }) {
                        Text("Submit Ticket")
                            .font(.system(.headline, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(isFormValid ? .blue : .gray)
                    .padding(.horizontal, 24)
                    .disabled(!isFormValid)
                    .listRowInsets(EdgeInsets())                  // zero padding on the row
                        .listRowBackground(Color.clear)  
                }
            }
            .navigationTitle("New Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Submission Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task {
                    for photo in newPhotos {
                        if let data = try? await photo.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            photoImages.append(image)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraVieww { image in
                    if let image = image {
                        photoImages.append(image)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if selectedIssueCategory == .tripIssue {
            return selectedTrip != nil && !description.isEmpty
        } else {
            return selectedVehicle != nil && !description.isEmpty
        }
    }
    
    private func validateAndSubmit() {
        guard !description.isEmpty else {
            alertMessage = "Please add a description of the issue."
            showAlert = true
            return
        }
        
        let vehicleNumber: String
        if selectedIssueCategory == .tripIssue {
            guard let trip = selectedTrip else {
                alertMessage = "Please select a trip."
                showAlert = true
                return
            }
            // In a real app, we would fetch the vehicle details using trip.vehicleId
            vehicleNumber = "KA01AB1234" // Mock vehicle number
        } else {
            guard let vehicle = selectedVehicle else {
                alertMessage = "Please select a vehicle."
                showAlert = true
                return
            }
            vehicleNumber = vehicle.licensePlate
        }
        
        ticketManager.addTicket(
            vehicleNumber: vehicleNumber,
            issueType: issueType.rawValue,
            description: description,
            priority: priority.rawValue
        )
        
        dismiss()
    }
}

// MARK: - Trip Selection View
struct TripSelectionView: View {
    @Binding var selectedTrip: Trip?
    @State private var showTripPicker = false
    
    // Mock data for trips
    let mockTrips: [Trip] = [
        Trip(
            id: "1",
            driverId: "driver1",
            vehicleId: "vehicle1",
            startLocation: "Chennai",
            endLocation: "Bangalore",
            date: "2024-04-25",
            time: "09:00",
            startTime: Date(),
            status: .assigned,
            vehicleType: "Passenger Vehicle",
            passengers: 4,
            loadWeight: nil
        ),
        Trip(
            id: "2",
            driverId: "driver1",
            vehicleId: "vehicle2",
            startLocation: "Mumbai",
            endLocation: "Pune",
            date: "2024-04-26",
            time: "14:00",
            startTime: Date(),
            status: .assigned,
            vehicleType: "Cargo Vehicle",
            passengers: nil,
            loadWeight: 500
        )
    ]
    
    var body: some View {
        Button {
            showTripPicker = true
        } label: {
            HStack {
                if let trip = selectedTrip {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(trip.startLocation) → \(trip.endLocation)")
                        Text("\(trip.date) at \(trip.time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Select Trip")
                        .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showTripPicker) {
            NavigationStack {
                List(mockTrips) { trip in
                    Button {
                        selectedTrip = trip
                        showTripPicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(trip.startLocation) → \(trip.endLocation)")
                                    .font(.headline)
                                Text("\(trip.date) at \(trip.time)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(trip.vehicleType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedTrip?.id == trip.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Select Trip")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showTripPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Vehicle Selection View
struct VehicleSelectionView: View {
    @Binding var selectedVehicle: Vehicle?
    @State private var showVehiclePicker = false
    
    // Mock data for vehicles
    let mockVehicles: [Vehicle] = [
        Vehicle(
            id: UUID(),
            make: "Toyota",
            model: "Innova",
            year: "2023",
            vin: "ABC123",
            licensePlate: "KA01AB1234",
            vehicleType: .car,
            status: .active,
            assignedDriverId: nil,
            passengerCapacity: 7,
            cargoCapacity: nil
        ),
        Vehicle(
            id: UUID(),
            make: "Tata",
            model: "407",
            year: "2023",
            vin: "XYZ789",
            licensePlate: "KA01CD5678",
            vehicleType: .truck,
            status: .active,
            assignedDriverId: nil,
            passengerCapacity: nil,
            cargoCapacity: 1000
        )
    ]
    
    var body: some View {
        Button {
            showVehiclePicker = true
        } label: {
            HStack {
                if let vehicle = selectedVehicle {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.licensePlate)
                        Text("\(vehicle.make) \(vehicle.model)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Select Vehicle")
                        .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showVehiclePicker) {
            NavigationStack {
                List(mockVehicles) { vehicle in
                    Button {
                        selectedVehicle = vehicle
                        showVehiclePicker = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.licensePlate)
                                    .font(.headline)
                                Text("\(vehicle.make) \(vehicle.model) (\(vehicle.year))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(vehicle.vehicleType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedVehicle?.id == vehicle.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .navigationTitle("Select Vehicle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showVehiclePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Camera View
struct CameraVieww: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage?) -> Void
        
        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                completion(image)
            } else {
                completion(nil)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    AddTicketView(ticketManager: TicketManager())
}
