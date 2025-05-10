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
    
    @Environment(\.presentationMode) var presentationMode
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
    @State private var minimizedAndReopened = false
    @State private var wasMinimized = false
    @State private var showBackAlert = false
    @State private var routeUpdateTrigger: UUID = UUID() // Force UI refresh
    
    // Emergency calling related states
    @State private var showEmergencyCallOptions = false
    
    // Payment proof related states
    @State private var isImagePickerPresented = false
    @State private var selectedImageData: Data? = nil
    @State private var showImagePreview = false
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var imageDescription: String = ""
    
    // Filter related states
    @State private var selectedFilter: FilterType = .none
    @State private var poiAnnotations: [CustomPointAnnotation] = []
    @State private var showFilterOptions = false
    
    @State private var showDeviationAlert = false
    
    // New state for the single selected stop
    @State private var selectedStop: CustomPointAnnotation? = nil
    @State private var showAddStopAlert = false
    @State private var tappedAnnotation: CustomPointAnnotation?

    private var minCardHeight: CGFloat { 220 }
    private var midCardHeight: CGFloat { screenHeight * 0.4 }
    private var maxCardHeight: CGFloat { screenHeight * 0.75 }
    
    enum FilterType: String {
        case none = "None"
        case hospital = "Hospitals"
        case petrolPump = "Petrol Pumps"
        case mechanics = "Mechanics"
        case pickup = "Pickup"
        case drop = "Drop"
        case car = "Car"
    }
    
    // MARK: - Subviews
    
    private var mapView: some View {
        ZStack {
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
                userLocationCoordinate: navigationVM.userLocation,
                poiAnnotations: poiAnnotations,
                selectedStop: $selectedStop,
                onAnnotationTap: { annotation in
                    if let customAnnotation = annotation as? CustomPointAnnotation,
                       [.hospital, .petrolPump, .mechanics].contains(customAnnotation.annotationType) {
                        tappedAnnotation = customAnnotation
                        showAddStopAlert = true
                    }
                }
            )
            .id(routeUpdateTrigger) // Force map refresh on route change
            
            if navigationVM.hasDeviatedFromRoute {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Route Deviation Detected")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Deviation: \(Int(navigationVM.deviationDistance)) m")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.red.opacity(0.95))
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 160)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: navigationVM.hasDeviatedFromRoute)
            }
        }
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
                    Button(action: {
                        showFilterOptions.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.2), radius: 3)
                            VStack(spacing: 2) {
                                Rectangle()
                                    .fill(selectedFilter == .none ? Color.blue : Color.orange)
                                    .frame(width: 20, height: 2)
                                Rectangle()
                                    .fill(selectedFilter == .none ? Color.blue : Color.orange)
                                    .frame(width: 16, height: 2)
                                Rectangle()
                                    .fill(selectedFilter == .none ? Color.blue : Color.orange)
                                    .frame(width: 12, height: 2)
                            }
                        }
                    }
                }
                .padding(.trailing, 12)
                .padding(.top, 16)
            }
            Spacer()
        }
    }
    
    private var emergencyCallButton: some View {
        VStack {
            Spacer().frame(height: 206)
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Button(action: {
                        showEmergencyCallOptions = true
                    }) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.3), radius: 4)
                    }
                    Text("Emergency")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                }
                .padding(.trailing, 12)
            }
            Spacer()
        }
    }
    
    private var emergencyCallOptionsView: some View {
        Group {
            if showEmergencyCallOptions {
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Text("Emergency Call Options")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        
                        Button(action: {
                            if let url = URL(string: "tel://7440312800") {
                                UIApplication.shared.open(url)
                            }
                            showEmergencyCallOptions = false
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("Call Fleet Manager")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                Color.gray.opacity(0.1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .cornerRadius(12)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            if let url = URL(string: "tel://1033") {
                                UIApplication.shared.open(url)
                            }
                            showEmergencyCallOptions = false
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                Text("Call NHAI Assistance")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                Color.gray.opacity(0.1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .cornerRadius(12)
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            showEmergencyCallOptions = false
                        }) {
                            Text("Cancel")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Color.gray.opacity(0.1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            .cornerRadius(12)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 16)
                    .background(
                        Color.white
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -4)
                    )
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showEmergencyCallOptions)
                }
                .edgesIgnoringSafeArea(.bottom)
                .background(
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showEmergencyCallOptions = false
                        }
                )
            }
        }
    }
    
    struct BlurView: UIViewRepresentable {
        func makeUIView(context: Context) -> UIVisualEffectView {
            let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
            return view
        }
        
        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
    }
    
    struct FilterButton: View {
        let icon: String
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                    Text(title)
                        .font(.body)
                        .fontWeight(isSelected ? .bold : .medium)
                        .foregroundColor(.blue)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    Color.gray.opacity(0.1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .cornerRadius(12)
            }
        }
    }

    private var filterOptionsView: some View {
        Group {
            if showFilterOptions {
                ZStack {
                    BlurView()
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            toggleFilter(.none)
                            showFilterOptions = false
                        }
                    
                    VStack {
                        VStack(spacing: 0) {
                            Text("HELP POINTS")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                            
                            FilterButton(
                                icon: "cross.circle.fill",
                                title: "Hospitals",
                                isSelected: selectedFilter == .hospital
                            ) {
                                toggleFilter(.hospital)
                                showFilterOptions = false
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                            
                            FilterButton(
                                icon: "fuelpump.fill",
                                title: "Petrol Pumps",
                                isSelected: selectedFilter == .petrolPump
                            ) {
                                toggleFilter(.petrolPump)
                                showFilterOptions = false
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                            
                            FilterButton(
                                icon: "wrench.and.screwdriver.fill",
                                title: "Mechanics",
                                isSelected: selectedFilter == .mechanics
                            ) {
                                toggleFilter(.mechanics)
                                showFilterOptions = false
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                toggleFilter(.none)
                                showFilterOptions = false
                            }) {
                                Text("Cancel")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        Color.gray.opacity(0.1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .cornerRadius(12)
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 16)
                        .background(
                            Color.white
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        )
                        .padding(.top, 100)
                        .padding(.horizontal, 16)
                    }
                    .edgesIgnoringSafeArea(.top)
                    .transition(.move(edge: .top))
                    .animation(.spring(), value: showFilterOptions)
                }
            }
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
        VStack {
            Spacer()
            
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
                        navigateToPostInspection: $navigateToPostInspection,
                        navigationVM: navigationVM,
                        trip: trip,
                        selectedStop: $selectedStop,
                        routeUpdateTrigger: $routeUpdateTrigger,
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
                        },
                        onRemoveStop: {
                            selectedStop = nil
                            navigationVM.updateRouteWithStop(stop: nil) {
                                if let route = navigationVM.route {
                                    let rect = route.polyline.boundingMapRect
                                    region = MKCoordinateRegion(rect)
                                    routeUpdateTrigger = UUID()
                                    print("Removed stop: New route distance = \(route.distance) meters, ETA = \(route.expectedTravelTime) seconds")
                                }
                            }
                        }
                    )
                )
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
        .edgesIgnoringSafeArea(.bottom)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
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
                        
                        requestCallPermission()
                        
                        NotificationCenter.default.addObserver(
                            forName: UIApplication.willResignActiveNotification,
                            object: nil,
                            queue: .main
                        ) { _ in
                            wasMinimized = true
                            print("App will resign active")
                        }
                        
                        NotificationCenter.default.addObserver(
                            forName: UIApplication.didBecomeActiveNotification,
                            object: nil,
                            queue: .main
                        ) { _ in
                            if wasMinimized {
                                minimizedAndReopened = true
                                wasMinimized = false
                            }
                        }
                    }
                    .onDisappear {
                        if !isTripStarted {
                            navigationVM.stopGeofencing()
                        }
                        NotificationCenter.default.removeObserver(
                            self,
                            name: UIApplication.willResignActiveNotification,
                            object: nil
                        )
                        NotificationCenter.default.removeObserver(
                            self,
                            name: UIApplication.didBecomeActiveNotification,
                            object: nil
                        )
                    }
                    .onChange(of: navigationVM.route) { newRoute in
                        if let route = newRoute {
                            let rect = route.polyline.boundingMapRect
                            region = MKCoordinateRegion(rect)
                            routeUpdateTrigger = UUID()
                            print("Route changed: Distance = \(route.distance) meters, ETA = \(route.expectedTravelTime) seconds")
                        }
                    }
                
                floatingButtons
                emergencyCallButton
                bottomCard
                expenseModal
                emergencyCallOptionsView
                filterOptionsView
                
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
            .navigationTitle("Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showBackAlert = true
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                        Text("Back")
                            .foregroundColor(.blue)
                    }
                }
            }
            .interactiveDismissDisabled()
            .presentationDetents([.large])
            .alert(isPresented: $showBackAlert) {
                Alert(
                    title: Text("Confirm"),
                    message: Text("Going back will reset the trip."),
                    primaryButton: .destructive(Text("Continue")) {
                        navigationVM.resetTrip()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .alert(isPresented: $showAddStopAlert) {
                Alert(
                    title: Text("Add Stop"),
                    message: Text("Add \(tappedAnnotation?.title ?? "this location") as a stop?"),
                    primaryButton: .default(Text("Add")) {
                        if let annotation = tappedAnnotation {
                            selectedStop = annotation
                            navigationVM.updateRouteWithStop(stop: annotation) {
                                if let route = navigationVM.route {
                                    let rect = route.polyline.boundingMapRect
                                    region = MKCoordinateRegion(rect)
                                    routeUpdateTrigger = UUID()
                                    print("Added stop: New route distance = \(route.distance) meters, ETA = \(route.expectedTravelTime) seconds")
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .fullScreenCover(isPresented: $navigateToPostInspection) {
                PostInspectionView(
                    authVM: authVM,
                    dropoffLocation: trip.endLocation,
                    vehicleNumber: vehicleNumber,
                    tripID: trip.id,
                    vehicleID: trip.vehicleId,
                  
                )
            }
            .dismissKeyboard()
        }
    }
    
    private func resetRootView<V: View>(to view: V) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("Failed to access UIWindow")
            return
        }
        
        let hostingController = UIHostingController(rootView: view)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
    }
    
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
    
    private func requestCallPermission() {
        print("Call permission is implicitly granted on iOS")
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
    
    private func toggleFilter(_ filter: FilterType) {
        if selectedFilter == filter {
            selectedFilter = .none
            poiAnnotations = []
        } else {
            selectedFilter = filter
            searchNearbyPOIs(filter: filter)
        }
    }
    
    private func searchNearbyPOIs(filter: FilterType) {
        guard let pickup = navigationVM.pickupLocation?.coordinate,
              let drop = navigationVM.dropLocation?.coordinate else {
            print("No valid pickup or drop coordinates available")
            poiAnnotations = []
            return
        }
        
        let searchTerm: String
        switch filter {
        case .hospital:
            searchTerm = "hospital, local hospital, clinic, medical center, urgent care, emergency room, health clinic"
        case .petrolPump:
            searchTerm = "gas station, fuel, petrol station, service station"
        case .mechanics:
            searchTerm = "auto repair, car repair, mechanic shop, automotive service, vehicle repair, auto service, garage"
        case .none, .pickup, .drop, .car:
            poiAnnotations = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchTerm
        request.resultTypes = .pointOfInterest
        
        let coordinates = [pickup, drop]
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let baseLatDelta = maxLat - minLat
        let baseLonDelta = maxLon - minLon
        let minDelta = 0.1
        let span = MKCoordinateSpan(
            latitudeDelta: max(baseLatDelta * 2.0, minDelta),
            longitudeDelta: max(baseLonDelta * 2.0, minDelta)
        )
        request.region = MKCoordinateRegion(center: center, span: span)
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                print("Error searching for \(searchTerm): \(error?.localizedDescription ?? "Unknown error")")
                self.poiAnnotations = []
                return
            }
            
            print("Found \(response.mapItems.count) results for \(searchTerm) in region: \(request.region)")
            
            self.poiAnnotations = response.mapItems.map { item in
                let annotation = CustomPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                switch filter {
                case .hospital:
                    annotation.annotationType = .hospital
                case .petrolPump:
                    annotation.annotationType = .petrolPump
                case .mechanics:
                    annotation.annotationType = .mechanics
                default:
                    annotation.annotationType = .none
                }
                return annotation
            }
            
            print("\(filter.rawValue) found: \(self.poiAnnotations.map { $0.title ?? "Unnamed" })")
        }
    }
}

struct BottomCardContent: View {
    let cardHeight: CGFloat
    let bottomSafeAreaInset: CGFloat
    @Binding var isTripStarted: Bool
    @Binding var selectedImageData: Data?
    @Binding var showImagePreview: Bool
    @Binding var navigateToPostInspection: Bool
    @ObservedObject var navigationVM: NavigationViewModel
    let trip: Trip
    @Binding var selectedStop: CustomPointAnnotation?
    @Binding var routeUpdateTrigger: UUID
    let onStartEndTrip: () -> Void
    let onFuelLog: () -> Void
    let onTollFees: () -> Void
    let onMisc: () -> Void
    let onRemoveStop: () -> Void
    
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
                    if selectedStop != nil {
                        stopDetails
                    }
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
                .id(routeUpdateTrigger) // Force refresh on route change
            }
            .padding(.bottom, 10)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 25) {
            Button(action: {
                if isTripStarted {
                    navigationVM.stopGeofencing()
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
                }
                isTripStarted.toggle()
            }) {
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
    
    private var stopDetails: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.purple)
                    .frame(width: 25)
                VStack(alignment: .leading) {
                    Text("Stop")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(selectedStop?.title ?? "Stop")
                        .font(.subheadline)
                        .lineLimit(2)
                }
                Spacer()
                Button(action: onRemoveStop) {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                        .frame(width: 25)
                }
            }
            .padding(.trailing, 8)
        }
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
                    .id(routeUpdateTrigger)
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
            if selectedStop != nil {
                HStack(alignment: .top) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.purple)
                        .frame(width: 25)
                    VStack(alignment: .leading) {
                        Text("Stop")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(selectedStop?.title ?? "Stop")
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(.trailing, 8)
            }
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
                    .id(routeUpdateTrigger)
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
                    .id(routeUpdateTrigger)
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
            .dismissKeyboardOnTap()
            .dismissKeyboardOnScroll()
            
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
