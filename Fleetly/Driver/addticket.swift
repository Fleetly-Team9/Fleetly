import SwiftUI
import PhotosUI
import AVFoundation

struct AddTicketView: View {
    @State private var vehicleNumber: String = ""
    @State private var issueType: IssueType = .tripIssue
    @State private var description: String = ""
    @State private var priority: Priority = .low
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticketManager: TicketManager
    
    let vehicles = ["KA01AB4321", "KA01AB4322", "KA01AB4323"]
    
    enum IssueType: String, CaseIterable, Identifiable {
        case tripIssue = "Trip Issue"
        case vehicleProblem = "Vehicle Problem"
        case payment = "Payment"
        case other = "Other"
        var id: String { rawValue }
    }
    
    enum Priority: String, CaseIterable, Identifiable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VehicleNumberSection(
                        vehicleNumber: $vehicleNumber,
                        vehicles: vehicles
                    )
                    IssueTypeSection(issueType: $issueType)
                    DescriptionSection(description: $description)
                    AttachmentsSection(selectedPhotos: $selectedPhotos, photoImages: $photoImages)
                    PrioritySection(priority: $priority)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            validateAndSubmit()
                        }) {
                            Text("Submit")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        .disabled(vehicleNumber.isEmpty || description.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Raise a Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Submission Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task {
                    photoImages.removeAll()
                    for photo in newPhotos {
                        if let data = try? await photo.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            photoImages.append(image)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
        }
    }
    
    private func validateAndSubmit() {
        guard !vehicleNumber.isEmpty else {
            alertMessage = "Vehicle Number is required."
            showAlert = true
            return
        }
        guard !description.isEmpty else {
            alertMessage = "Description is required."
            showAlert = true
            return
        }
        
        ticketManager.addTicket(
            vehicleNumber: vehicleNumber,
            issueType: issueType.rawValue,
            description: description,
            priority: priority.rawValue
        )
        
        print("Ticket submitted: Vehicle: \(vehicleNumber), Issue: \(issueType.rawValue), Description: \(description), Priority: \(priority.rawValue), Photos: \(photoImages.count)")
        
        dismiss()
    }
}

// MARK: - Subviews

struct VehicleNumberSection: View {
    @Binding var vehicleNumber: String
    let vehicles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VEHICLE NUMBER")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            Menu {
                ForEach(vehicles, id: \.self) { vehicle in
                    Button(action: {
                        vehicleNumber = vehicle
                    }) {
                        Text(vehicle)
                    }
                }
            } label: {
                HStack {
                    Text(vehicleNumber.isEmpty ? "Select vehicle" : vehicleNumber)
                        .foregroundStyle(vehicleNumber.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct IssueTypeSection: View {
    @Binding var issueType: AddTicketView.IssueType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ISSUE TYPE")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            Menu {
                ForEach(AddTicketView.IssueType.allCases) { type in
                    Button(action: {
                        issueType = type
                    }) {
                        Text(type.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text(issueType.rawValue)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct DescriptionSection: View {
    @Binding var description: String
    @State private var isRecording = false
    @State private var audioURL: URL?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playerDelegate: AVPlayerDelegateBridge?
    
    let audioSession = AVAudioSession.sharedInstance()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DESCRIPTION")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            VStack(spacing: 12) {
                if isRecording {
                    VStack(spacing: 8) {
                        Text("Recording...")
                            .foregroundColor(.red)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                } else if audioURL == nil {
                    Text("Tap the mic to record an audio description")
                        .foregroundColor(.gray)
                } else {
                    Text("Audio recorded. You can play or delete it.")
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        isRecording ? stopRecording() : startRecording()
                    }) {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(isRecording ? Color.red : Color.green))
                            .shadow(radius: 4)
                    }
                    
                    if let _ = audioURL {
                        Button(action: {
                            playAudio()
                        }) {
                            HStack {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                Text(isPlaying ? "Pause" : "Play")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            deleteRecording()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.white))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            setupAudioSession()
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func startRecording() {
        let fileName = UUID().uuidString + ".m4a"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.record()
            isRecording = true
            audioURL = path
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    private func playAudio() {
        guard let url = audioURL else { return }
        
        do {
            if isPlaying {
                audioPlayer?.pause()
                isPlaying = false
            } else {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                let delegate = AVPlayerDelegateBridge {
                    isPlaying = false
                }
                audioPlayer?.delegate = delegate
                playerDelegate = delegate
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isPlaying = true
            }
        } catch {
            print("Playback failed: \(error)")
            isPlaying = false
        }
    }
    
    private func deleteRecording() {
        if let url = audioURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioURL = nil
        isPlaying = false
        audioPlayer = nil
    }
}

class AVPlayerDelegateBridge: NSObject, AVAudioPlayerDelegate {
    var onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

struct AttachmentsSection: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Binding var photoImages: [UIImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPLOAD A PHOTO")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            PhotosPicker(
                selection: $selectedPhotos,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "camera")
                        .foregroundStyle(.gray)
                    Text("Upload Photo")
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            if !photoImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photoImages.indices, id: \.self) { index in
                            Image(uiImage: photoImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct PrioritySection: View {
    @Binding var priority: AddTicketView.Priority
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRIORITY")
                .font(.subheadline)
                .foregroundStyle(.orange)
            
            Menu {
                ForEach(AddTicketView.Priority.allCases) { priority in
                    Button(action: {
                        self.priority = priority
                    }) {
                        Text(priority.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text(priority.rawValue)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.gray)
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    AddTicketView(ticketManager: TicketManager())
}
