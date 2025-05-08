import Foundation
import SwiftUI
import FirebaseFirestore

class PastRidesViewModel: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var canLoadMore: Bool = true

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    private var driverId: String
    private let calendar = Calendar.current

    init(driverId: String) {
        self.driverId = driverId
    }

    deinit {
        listener?.remove()
    }

    func updateDriverId(_ driverId: String) {
        guard self.driverId != driverId else { return }
        self.driverId = driverId
        lastDocument = nil
        rides = []
        fetchCompletedRides()
    }

    func fetchCompletedRides() {
        guard !driverId.isEmpty else {
            errorMessage = "Driver ID is missing"
            return
        }

        guard !isLoading else { return }
        
        isLoading = true
        listener?.remove()

        print("Fetching trips for driverId: \(driverId)")

        var query = db.collection("trips")
            .whereField("status", isEqualTo: "completed")
            .whereField("driverId", isEqualTo: driverId)
            .order(by: "endTime", descending: true)
            .limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to fetch rides: \(error.localizedDescription)"
                print("Query error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.errorMessage = "No rides found"
                self.canLoadMore = false
                print("No documents found for query")
                return
            }
            
            print("Found \(documents.count) documents")
            self.lastDocument = documents.last
            
            var tempRides: [Ride] = documents.compactMap { doc in
                do {
                    let ride = try doc.data(as: Ride.self)
                    print("Decoded ride: \(ride.id ?? "no id") with endTime: \(ride.endTime.description)")
                    return ride
                } catch {
                    self.errorMessage = "Error decoding ride: \(error.localizedDescription)"
                    print("Decoding error: \(error.localizedDescription)")
                    return nil
                }
            }
            
            let group = DispatchGroup()
            for (index, var ride) in tempRides.enumerated() {
                guard let tripID = ride.id else { continue }
                
                group.enter()
                db.collection("trips").document(tripID).collection("preinspection").getDocuments { snapshot, error in
                    defer { group.leave() }
                    if let error = error {
                        self.errorMessage = "Failed to fetch preinspection: \(error.localizedDescription)"
                        print("Preinspection error: \(error.localizedDescription)")
                        return
                    }
                    if let doc = snapshot?.documents.first {
                        do {
                            tempRides[index].preInspection = try doc.data(as: Inspection.self)
                        } catch {
                            self.errorMessage = "Error decoding preinspection: \(error.localizedDescription)"
                            print("Preinspection decode error: \(error.localizedDescription)")
                        }
                    }
                }
                
                group.enter()
                db.collection("trips").document(tripID).collection("postinspection").getDocuments { snapshot, error in
                    defer { group.leave() }
                    if let error = error {
                        self.errorMessage = "Failed to fetch postinspection: \(error.localizedDescription)"
                        print("Postinspection error: \(error.localizedDescription)")
                        return
                    }
                    if let doc = snapshot?.documents.first {
                        do {
                            tempRides[index].postInspection = try doc.data(as: Inspection.self)
                        } catch {
                            self.errorMessage = "Error decoding postinspection: \(error.localizedDescription)"
                            print("Postinspection decode error: \(error.localizedDescription)")
                        }
                    }
                }
                
                group.enter()
                db.collection("trips").document(tripID).getDocument { snapshot, error in
                    defer { group.leave() }
                    if let error = error {
                        self.errorMessage = "Failed to fetch trip: \(error.localizedDescription)"
                        print("Trip error: \(error.localizedDescription)")
                        return
                    }
                    if let doc = snapshot {
                        do {
                            let trip = try doc.data(as: Trip.self)
                            // Fetch trip charges from subcollection
                            FirebaseManager.shared.fetchTripCharges(tripId: tripID) { result in
                                switch result {
                                case .success(let charges):
                                    tempRides[index].tripCharges = charges
                                case .failure(let error):
                                    print("Error fetching trip charges: \(error)")
                                }
                            }
                        } catch {
                            self.errorMessage = "Error decoding trip: \(error.localizedDescription)"
                            print("Trip decode error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                // Filter rides to match the selectedDate based on endTime
                let filteredRides = tempRides.filter { ride in
                    self.calendar.isDate(ride.endTime, inSameDayAs: self.selectedDate)
                }
                
                if self.lastDocument == nil {
                    self.rides = filteredRides
                } else {
                    self.rides.append(contentsOf: filteredRides)
                }
                self.canLoadMore = tempRides.count == self.pageSize
                print("Filtered rides for \(self.selectedDate): \(self.rides.count)")
                
                if self.rides.isEmpty {
                    self.errorMessage = "No rides found on this date"
                } else {
                    self.errorMessage = nil
                }
            }
        }
    }

    func loadMoreRides() {
        guard canLoadMore, !isLoading else { return }
        fetchCompletedRides()
    }

    func updateSelectedDate(_ date: Date) {
        print("Updating selected date to: \(date)")
        selectedDate = date
        lastDocument = nil
        rides = []
        fetchCompletedRides()
    }

    func dayHasRides(_ date: Date) -> Bool {
        return rides.contains { ride in
            return calendar.isDate(ride.endTime, inSameDayAs: date)
        }
    }

    func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    func daysInMonth() -> [[Date?]] {
        let calendar = Calendar.current
        let monthRange = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let daysCount = monthRange.count
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...daysCount {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }

        let totalSlots = days.count % 7 == 0 ? days.count : (days.count / 7 + 1) * 7
        days.append(contentsOf: Array(repeating: nil, count: totalSlots - days.count))

        var weeks: [[Date?]] = []
        for i in stride(from: 0, to: days.count, by: 7) {
            weeks.append(Array(days[i..<min(i + 7, days.count)]))
        }
        return weeks
    }

    func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        return currentMonthComponents == dateComponents
    }
}
