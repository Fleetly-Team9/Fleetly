import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let err = error {
                print("Notification auth error:", err)
            } else {
                print("Notification permission granted:", granted)
            }
        }
    }
    
    func scheduleNewTripNotification(trip: Trip) {
        print("🆕 Scheduling notification for trip \(trip.id)")
        let content = UNMutableNotificationContent()
        content.title = "New Trip Assigned"
        content.body  = "Pickup: \(trip.startLocation) → Drop: \(trip.endLocation) at \(trip.time)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "newTrip_\(trip.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let err = error {
                print("❌ Failed to schedule notification:", err)
            } else {
                print("✅ Notification scheduled!")
            }
        }
    }

}
