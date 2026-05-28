import Foundation
import UserNotifications

/// Schedules a single daily local notification that wakes the wrist with the system
/// "notification" haptic. Tapping the notification opens the watch app to today's devotional.
enum ReminderScheduler {
    static let identifier = "swiftbible.watch.daily-devotional-reminder"

    /// Persists the hour/minute chosen by the user.
    static var hour: Int {
        get { UserDefaults.standard.object(forKey: "reminderHour") as? Int ?? 8 }
        set { UserDefaults.standard.set(newValue, forKey: "reminderHour") }
    }

    static var minute: Int {
        get { UserDefaults.standard.object(forKey: "reminderMinute") as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: "reminderMinute") }
    }

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "reminderEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "reminderEnabled") }
    }

    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
        }
    }

    static func schedule(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
        self.isEnabled = true

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Daily Devotional"
        content.body = "A word for today is ready."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        center.add(request, withCompletionHandler: nil)
    }

    static func cancel() {
        isEnabled = false
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
