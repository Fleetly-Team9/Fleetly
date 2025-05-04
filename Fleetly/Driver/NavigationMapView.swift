import SwiftUI
import MapKit
import UIKit
import Firebase
import FirebaseFirestore
import PhotosUI

struct NavigationMapView: View {
    let trip: Trip
    let vehicleID: String
    let vehicleNumber: String
    let authVM: AuthViewModel
    
    @StateObject private var navigationVM = NavigationViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var cardHeight: CGFloat = 220
    @State private var mapStyle = MapStyle.standard
    @State private var showFuelLogModal = false
    @State private var showTollModal = false
    @State private var showMiscModal = false
    @State private var expenseAmount = ""
    @State private var activeExpenseType = ExpenseType.none
    @State private var isTripStarted = false
    @State private var navigateToPostInspection = false
    @State private var screenHeight: CGFloat = UIScreen.main.bounds.height
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    @State private var bottomSafeAreaInset: CGFloat = 0
    
    // Payment proof related states
    @State private var isImagePickerPresented = false
    @State private var selectedImageData: Data? = nil
    @State private var showImagePreview = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var imageDescription: String = ""
    
    private var minCardHeight: CGFloat { 220 }
    private var midCardHeight: CGFloat { screenHeight * 0.4 }
    private var maxCardHeight: CGFloat { screenHeight * 0.75 }
    
    // MARK: - Subviews
    
    private var mapView: some View {
        MapViewWithRoute(
            region: $region,
            pickup: navigationVM.pickupLocation ?? Location(
                name: trip.startLocation,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            ),
            drop: navigationVM.dropLocation ?? Location(
                name: trip.endLocation,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            ),
            route: navigationVM.route,
            mapStyle: $mapStyle,
            isTripStarted: isTripStarted,
            userLocationCoordinate: navigationVM.userLocation
        )
    }
    
    private var floatingButtons: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Button(action: {
                        mapStyle = mapStyle == .standard ? .satellite : .standard
                    }) {
                        Image(systemName: mapStyle == .standard ? "globe" : "map")
                            .padding(10)
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 3)
                    }
                    Button(action: {
                        if let route = navigationVM.route {
                            let rect = route.polyline.boundingMapRect
                            region = MKCoordinateRegion(rect)
                        } else if let userLocation = navigationVM.userLocation {
                            region.center = userLocation
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .padding(10)
                            .background(Color.white)
                            .foregroundColor(.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 3)
                    }
                }
                .padding(.trailing, 12)
                .padding(.top, 16)
            }
            Spacer()
        }
    }
    
    private var emergencyButton: some View {
        HStack {
            Spacer()
            Button(action: {
                if let url = URL(string: "tel://1033") {
                    UIApplication.shared.open(url)
                }
            }) {
                VStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 22))
                        .padding(14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                    Text("Emergency")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(4)
                }
            }
            .padding(.trailing, 12)
        }
    }
    
    private var expenseModal: some View {
        Group {
            if showFuelLogModal || showTollModal || showMiscModal {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        closeAllModals()
                    }
                
                ExpenseModalView(
                    activeExpenseType: activeExpenseType,
                    expenseAmount: $expenseAmount,
                    selectedImageData: $selectedImageData,
                    photoPickerItems: $photoPickerItems,
                    imageDescription: $imageDescription,
                    showImagePreview: $showImagePreview,
                    onClose: closeAllModals,
                    onSave: saveExpenseWithProof
                )
            }
        }
    }
    
    private var bottomCard: some View {
        Rectangle()
            .fill(Color(.systemBackground))
            .frame(width: screenWidth, height: cardHeight + bottomSafeAreaInset)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
            .overlay(
                BottomCardContent(
                    cardHeight: cardHeight,
                    bottomSafeAreaInset: bottomSafeAreaInset,
                    isTripStarted: $isTripStarted,
                    selectedImageData: $selectedImageData,
                    showImagePreview: $showImagePreview,
                    navigationVM: navigationVM,
                    trip: trip,
                    onStartEndTrip: {
                        if isTripStarted {
                            let endTime = Date()
                            FirebaseManager.shared.saveEndClicked(tripId: trip.id, timestamp: endTime) { result in
                                switch result {
                                case .success:
                                    print("Successfully saved EndClicked")
                                case .failure(let error):
                                    print("Error saving EndClicked: \(error)")
                                }
                            }
                            navigateToPostInspection = true
                        } else {
                            let startTime = Date()
                            navigationVM.startTime = startTime
                            FirebaseManager.shared.saveGoClicked(tripId: trip.id, timestamp: startTime) { result in
                                switch result {
                                case .success:
                                    print("Successfully saved GoClicked")
                                case .failure(let error):
                                    print("Error saving GoClicked: \(error)")
                                }
                            }
                            isTripStarted = true
                        }
                    },
                    onFuelLog: {
                        activeExpenseType = .fuel
                        expenseAmount = ""
                        selectedImageData = nil
                        imageDescription = ""
                        showFuelLogModal = true
                    },
                    onTollFees: {
                        activeExpenseType = .toll
                        expenseAmount = ""
                        selectedImageData = nil
                        imageDescription = ""
                        showTollModal = true
                    },
                    onMisc: {
                        activeExpenseType = .misc
                        expenseAmount = ""
                        selectedImageData = nil
                        imageDescription = ""
                        showMiscModal = true
                    }
                )
            )
            .position(x: screenWidth/2, y: screenHeight - cardHeight/2)
            .edgesIgnoringSafeArea(.bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = cardHeight + (-value.translation.height)
                        if newHeight >= minCardHeight && newHeight <= maxCardHeight {
                            cardHeight = newHeight
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.height < -20 {
                                if cardHeight < midCardHeight {
                                    cardHeight = midCardHeight
                                } else {
                                    cardHeight = maxCardHeight
                                }
                            } else if value.translation.height > 20 {
                                if cardHeight > midCardHeight {
                                    cardHeight = midCardHeight
                                } else {
                                    cardHeight = minCardHeight
                                }
                            } else {
                                if cardHeight < minCardHeight + (midCardHeight - minCardHeight) / 2 {
                                    cardHeight = minCardHeight
                                } else if cardHeight < midCardHeight + (maxCardHeight - midCardHeight) / 2 {
                                    cardHeight = midCardHeight
                                } else {
                                    cardHeight = maxCardHeight
                                }
                            }
                        }
                    }
            )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                mapView
                    .accentColor(.blue)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        navigationVM.startTrip(trip: trip)
                        screenHeight = geometry.size.height
                        screenWidth = geometry.size.width
                        bottomSafeAreaInset = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
                        if let userLocation = navigationVM.userLocation {
                            region.center = userLocation
                        } else if let pickupCoordinate = navigationVM.pickupLocation?.coordinate {
                            region.center = pickupCoordinate
                        }
                    }
                
                floatingButtons
                emergencyButton
                bottomCard
                expenseModal
                
                if showImagePreview, let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    ZStack {
                        Color.black.opacity(0.9)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                showImagePreview = false
                            }
                        
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showImagePreview = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                .padding()
                            }
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .padding()
                            
                            Spacer()
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationBarTitle("Navigation", displayMode: .inline)
            .toolbar(.hidden, for: .tabBar)
            .background(
                NavigationLink(
                    destination: PostInspectionView(
                        authVM: authVM,
                        dropoffLocation: trip.endLocation,
                        vehicleNumber: vehicleNumber,
                        tripID: trip.id,
                        vehicleID: trip.vehicleId
                    ),
                    isActive: $navigateToPostInspection
                ) {
                    EmptyView()
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func closeAllModals() {
        showFuelLogModal = false
        showTollModal = false
        showMiscModal = false
        activeExpenseType = .none
        showImagePreview = false
        selectedImageData = nil
        imageDescription = ""
        photoPickerItems = []
    }
    
    private func saveExpenseWithProof() {
        if let amount = Double(expenseAmount) {
            switch activeExpenseType {
            case .fuel:
                navigationVM.fuelExpense += amount
                if let imageData = selectedImageData {
                    navigationVM.fuelReceipt = imageData
                    navigationVM.hasFuelReceipt = true
                    navigationVM.fuelReceiptDescription = imageDescription
                }
            case .toll:
                navigationVM.tollExpense += amount
                if let imageData = selectedImageData {
                    navigationVM.tollReceipt = imageData
                    navigationVM.hasTollReceipt = true
                    navigationVM.tollReceiptDescription = imageDescription
                }
            case .misc:
                navigationVM.miscExpense += amount
                if let imageData = selectedImageData {
                    navigationVM.miscReceipt = imageData
                    navigationVM.hasMiscReceipt = true
                    navigationVM.miscReceiptDescription = imageDescription
                }
            case .none:
                break
            }
            navigationVM.updateTotalExpenses()
            FirebaseManager.shared.saveTripCharges(
                tripId: trip.id,
                misc: navigationVM.miscExpense,
                fuelLog: navigationVM.fuelExpense,
                tollFees: navigationVM.tollExpense,
                completion: { result in
                    switch result {
                    case .success:
                        print("Successfully saved trip charges to Firebase")
                    case .failure(let error):
                        print("Error saving trip charges: \(error)")
                    }
                }
            )
        }
    }
}

// MARK: - Bottom Card Content

struct BottomCardContent: View {
    let cardHeight: CGFloat
    let bottomSafeAreaInset: CGFloat
    @Binding var isTripStarted: Bool
    @Binding var selectedImageData: Data?
    @Binding var showImagePreview: Bool
    let navigationVM: NavigationViewModel
    let trip: Trip
    let onStartEndTrip: () -> Void
    let onFuelLog: () -> Void
    let onTollFees: () -> Void
    let onMisc: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 50, height: 5)
                .cornerRadius(2.5)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    actionButtons
                    Divider().padding(.vertical, 6)
                    tripStatus
                    Divider().padding(.vertical, 6)
                    locationDetails
                    Divider().padding(.vertical, 6)
                    tripMetrics
                    Divider().padding(.vertical, 6)
                    expenseDetails
                }
                .padding(.horizontal, 16)
                .padding(.bottom, bottomSafeAreaInset + 60)
            }
            .padding(.bottom, 10)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 25) {
            Button(action: onStartEndTrip) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isTripStarted ? Color.red : Color.blue)
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.black.opacity(0.2), radius: 4)
                        Text(isTripStarted ? "END" : "GO")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Text(isTripStarted ? "End Trip" : "Start Trip")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            ExpenseButton(icon: "fuelpump.fill", title: "Fuel Log", action: onFuelLog)
            ExpenseButton(icon: "road.lanes", title: "Toll Fees", action: onTollFees)
            ExpenseButton(icon: "dollarsign.circle", title: "Misc", action: onMisc)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    private var tripStatus: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(isTripStarted ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text(isTripStarted ? "Trip in Progress" : "Trip Ready")
                    .font(.headline)
                Spacer()
                Text(navigationVM.route?.expectedTravelTime.formattedTravelTime ?? "--")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var locationDetails: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                    .frame(width: 25)
                VStack(alignment: .leading) {
                    Text("Pickup")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(navigationVM.pickupLocation?.name ?? trip.startLocation)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.trailing, 8)
            HStack(alignment: .top) {
                Image(systemName: "location.fill")
                    .foregroundColor(.red)
                    .frame(width: 25)
                VStack(alignment: .leading) {
                    Text("Destination")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(navigationVM.dropLocation?.name ?? trip.endLocation)
                        .font(.subheadline)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(.trailing, 8)
        }
    }
    
    private var tripMetrics: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                    .frame(width: 25)
                Text("Distance:")
                    .font(.subheadline)
                Spacer()
                Text(navigationVM.route?.distance.formattedDistance ?? "--")
                    .font(.subheadline)
            }
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .frame(width: 25)
                Text("ETA:")
                    .font(.subheadline)
                Spacer()
                Text(Date().addingTimeInterval(navigationVM.route?.expectedTravelTime ?? 0).formattedETA)
                    .font(.subheadline)
            }
        }
    }
    
    private var expenseDetails: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "indianrupeesign.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 25)
                Text("Incidental Charges:")
                    .font(.subheadline)
                Spacer()
                Text("₹ \(navigationVM.totalExpenses, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            if navigationVM.totalExpenses > 0 {
                VStack(spacing: 10) {
                    if navigationVM.fuelExpense > 0 {
                        HStack {
                            Text("Fuel")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("₹ \(navigationVM.fuelExpense, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                    if navigationVM.tollExpense > 0 {
                        HStack {
                            Text("Toll")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("₹ \(navigationVM.tollExpense, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                    if navigationVM.miscExpense > 0 {
                        HStack {
                            Text("Misc")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("₹ \(navigationVM.miscExpense, specifier: "%.2f")")
                                .font(.caption)
                        }
                    }
                }
                .padding(.leading, 25)
            }
        }
    }
}

// MARK: - Expense Modal View

struct ExpenseModalView: View {
    let activeExpenseType: ExpenseType
    @Binding var expenseAmount: String
    @Binding var selectedImageData: Data?
    @Binding var photoPickerItems: [PhotosPickerItem]
    @Binding var imageDescription: String
    @Binding var showImagePreview: Bool
    let onClose: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)
            HStack {
                Text(getExpenseTitle())
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 15)
            .padding(.bottom, 0)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 25)
            
            VStack(spacing: 20) {
                Text("Enter Amount")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("₹")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    TextField("0", text: $expenseAmount)
                        .font(.system(size: 30))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(height: 60)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(15)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 15)
            
            // Payment proof section
            VStack(alignment: .leading, spacing: 15) {
                Text("Payment Proof")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if selectedImageData != nil {
                    HStack {
                        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    onClose()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        showImagePreview = true
                                    }
                                }
                        }
                        
                        Button(action: {
                            selectedImageData = nil
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                        .padding(.trailing, 16)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    PhotosPicker(
                        selection: $photoPickerItems,
                        maxSelectionCount: 1,
                        matching: .images
                    ) {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("Upload Bill / Screenshot")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                                .background(Color(.systemGray6).cornerRadius(10))
                        )
                    }
                    .padding(.horizontal, 16)
                    .onChange(of: photoPickerItems) { newItems in
                        guard let item = newItems.first else { return }
                        
                        item.loadTransferable(type: Data.self) { result in
                            switch result {
                            case .success(let data):
                                if let data = data {
                                    DispatchQueue.main.async {
                                        selectedImageData = data
                                        photoPickerItems = []
                                    }
                                }
                            case .failure:
                                print("Failed to load image data")
                            }
                        }
                    }
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    TextField("Add details about this expense", text: $imageDescription)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            
            Button(action: {
                onSave()
                onClose()
            }) {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .frame(height: 543)
    }
    
    private func getExpenseTitle() -> String {
        switch activeExpenseType {
        case .fuel:
            return "Petrol Pump"
        case .toll:
            return "Toll Fees"
        case .misc:
            return "Miscellaneous Expense"
        case .none:
            return ""
        }
    }
}
