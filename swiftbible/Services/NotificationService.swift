//
//  NotificationService.swift
//  swiftbible
//

import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let notificationIdentifier = "daily-devotional-reminder"

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[Notifications] Authorization request failed: \(error)")
            return false
        }
    }

    func scheduleDailyReminder(at time: Date) async {
        let granted = await requestAuthorization()
        guard granted else {
            print("[Notifications] Permission not granted")
            return
        }

        // Cancel existing before scheduling new
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Daily Devotional"
        content.body = "Your daily devotional is ready. Take a moment to reflect today."
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[Notifications] Daily reminder scheduled for \(dateComponents.hour ?? 0):\(String(format: "%02d", dateComponents.minute ?? 0))")
        } catch {
            print("[Notifications] Failed to schedule: \(error)")
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    // Handle notification tap - post notification to navigate to devotional tab
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let id = response.notification.request.identifier
        if id == notificationIdentifier || id == "test-devotional-reminder" {
            await MainActor.run {
                NotificationCenter.default.post(name: .devotionalReminderTapped, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let devotionalReminderTapped = Notification.Name("devotionalReminderTapped")
}
