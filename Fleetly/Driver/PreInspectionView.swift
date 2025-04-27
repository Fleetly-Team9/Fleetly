import Foundation
import SwiftUI
import PhotosUI

struct PreInspectionView: View {
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
    @ObservedObject var authVM: AuthViewModel
    let dropoffLocation: String
    let vehicleNumber: String
    
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
    
    var body: some View {
        NavigationView {
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
                            Text(vehicleNumber)
                        }
                        HStack {
                            Text("Pickup Location")
                            Spacer()
                            Text("Chennai")
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
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Toggle(isOn: $hornCheck) {
                            Text("Horns")
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Toggle(isOn: $clutchCheck) {
                            Text("Clutch")
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Toggle(isOn: $airbagsCheck) {
                            Text("Airbags")
                        }
                        .toggleStyle(CheckboxToggleStyle())
                        
                        Toggle(isOn: $physicalDamageCheck) {
                            Text("Physical damage")
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                    
                    Section {
                        VStack {
                            Toggle(isOn: $tyrePressureCheck) {
                                Text("Tyre Pressure")
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        TextField(
                            "Enter remarks",
                            text: $tyrePressureRemarks
                        )
                        .padding()
                    }
                    
                    Section {
                        VStack {
                            Toggle(isOn: $brakesCheck) {
                                Text("Brakes")
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        TextField(
                            "Enter remarks",
                            text: $brakeRemarks
                        )
                        .padding()
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
                        date: date
                    ) { result in
                        switch result {
                        case .success:
                            print("Inspection recorded successfully")
                        case .failure(let error):
                            print("Error recording inspection: \(error)")
                        }
                    }
                }) {
                    Text("Ready for trip")
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
            .navigationTitle(Text("Pre Inspection"))
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

struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreInspectionView(authVM: AuthViewModel(), dropoffLocation: "Mysore", vehicleNumber: "KA1234")
                .previewDisplayName("Light Mode")
            
            PreInspectionView(authVM: AuthViewModel(), dropoffLocation: "Mysore", vehicleNumber: "KA1234")
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
