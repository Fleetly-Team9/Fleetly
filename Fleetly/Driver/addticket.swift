import SwiftUI
import PhotosUI
import AVFoundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - View Model
class AddTicketViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var vehicleNumbers: [String: String] = [:] // Map of vehicleId to vehicleNumber
    
    private let db = Firestore.firestore()
    
    init() {
        fetchTrips()
        fetchVehicles()
    }
    
    func fetchTrips() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        db.collection("trips")
            .whereField("driverId", isEqualTo: userId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                self.trips = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trip.self)
                } ?? []
                
                // Fetch vehicle numbers for all trips
                for trip in self.trips {
                    self.fetchVehicleNumber(for: trip.vehicleId)
                }
                
                self.isLoading = false
            }
    }
    
    private func fetchVehicleNumber(for vehicleId: String) {
        db.collection("vehicles").document(vehicleId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let vehicleNumber = data["licensePlate"] as? String else { return }
            
            DispatchQueue.main.async {
                self.vehicleNumbers[vehicleId] = vehicleNumber
            }
        }
    }
    
    func fetchVehicles() {
        isLoading = true
        db.collection("vehicles")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                self.vehicles = snapshot?.documents.compactMap { document in
                    try? document.data(as: Vehicle.self)
                } ?? []
                
                self.isLoading = false
            }
    }
}

// MARK: - Main View
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
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticketManager: TicketManager
    @StateObject private var viewModel = AddTicketViewModel()
    
    // Add FocusState for text fields
    @FocusState private var isDescriptionFocused: Bool
    
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
    
    // Add dismissKeyboard function
    private func dismissKeyboard() {
        isDescriptionFocused = false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                            TripSelectionView(selectedTrip: $selectedTrip, trips: viewModel.trips, isLoading: viewModel.isLoading)
                        } else {
                            VehicleSelectionView(selectedVehicle: $selectedVehicle, vehicles: viewModel.vehicles, isLoading: viewModel.isLoading)
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
                                .focused($isDescriptionFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    dismissKeyboard()
                                }
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
                            if isSubmitting {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Submitting...")
                                        .font(.system(.headline, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            } else {
                                Text("Submit Ticket")
                                    .font(.system(.headline, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(isFormValid ? .blue : .gray)
                        .padding(.horizontal, 24)
                        .disabled(!isFormValid || isSubmitting)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .disabled(isSubmitting)
                .onTapGesture {
                    dismissKeyboard()
                }
                .gesture(
                    DragGesture()
                        .onChanged { _ in
                            dismissKeyboard()
                        }
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                    }
                }
                
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Submitting Ticket...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
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
                    .disabled(isSubmitting)
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
                ViewCamera { image in
                    if let image = image {
                        photoImages.append(image)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
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
        
        let vehicleId: String
        let vehicleNumber: String
        let tripId: String?
        
        if selectedIssueCategory == .tripIssue {
            guard let trip = selectedTrip else {
                alertMessage = "Please select a trip."
                showAlert = true
                return
            }
            vehicleId = trip.vehicleId
            vehicleNumber = viewModel.vehicleNumbers[trip.vehicleId] ?? "Unknown"
            tripId = trip.id
        } else {
            guard let vehicle = selectedVehicle else {
                alertMessage = "Please select a vehicle."
                showAlert = true
                return
            }
            vehicleId = vehicle.id.uuidString
            vehicleNumber = vehicle.licensePlate
            tripId = nil
        }
        
        // Show loading state
        isSubmitting = true
        
        // Submit ticket
        ticketManager.addTicket(
            category: selectedIssueCategory.rawValue,
            vehicleId: vehicleId,
            vehicleNumber: vehicleNumber,
            issueType: issueType.rawValue,
            description: description,
            priority: priority.rawValue,
            photos: photoImages.isEmpty ? nil : photoImages,
            tripId: tripId
        ) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = error
                    self.showAlert = true
                } else {
                    // Reset form and dismiss
                    self.resetForm()
                    self.dismiss()
                }
                self.isSubmitting = false
            }
        }
    }
    
    private func resetForm() {
        selectedIssueCategory = .tripIssue
        selectedTrip = nil
        selectedVehicle = nil
        issueType = .mechanical
        priority = .low
        description = ""
        selectedPhotos = []
        photoImages = []
    }
}

// MARK: - Trip Selection View
struct TripSelectionView: View {
    @Binding var selectedTrip: Trip?
    let trips: [Trip]
    let isLoading: Bool
    @State private var showTripPicker = false
    
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
                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if trips.isEmpty {
                        ContentUnavailableView(
                            "No Trips Available",
                            systemImage: "car",
                            description: Text("You don't have any assigned trips at the moment.")
                        )
                    } else {
                        List(trips) { trip in
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
                    }
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
    let vehicles: [Vehicle]
    let isLoading: Bool
    @State private var showVehiclePicker = false
    
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
                Group {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if vehicles.isEmpty {
                        ContentUnavailableView(
                            "No Vehicles Available",
                            systemImage: "car",
                            description: Text("There are no active vehicles at the moment.")
                        )
                    } else {
                        List(vehicles) { vehicle in
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
                    }
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
struct ViewCamera: UIViewControllerRepresentable {
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
