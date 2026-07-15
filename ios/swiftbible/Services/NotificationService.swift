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

    /// Schedule a daily repeating notification at the given time.
    /// Pulls today's cached devotional for a richer message if available.
    func scheduleDailyReminder(at time: Date) async {
        let granted = await requestAuthorization()
        guard granted else {
            print("[Notifications] Permission not granted")
            return
        }

        cancelDailyReminder()

        let content = buildContent(for: Date())

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

    // MARK: - Content

    func buildContent(for date: Date) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if let devotional = CacheService.shared.loadDevotional(for: date),
           let teaser = extractTeaser(from: devotional.cleanedForDisplay.message) {
            content.title = "Daily Devotional"
            content.body = teaser
        } else {
            content.title = "Daily Devotional"
            content.body = "Your daily devotional is ready. Take a moment to reflect."
        }

        return content
    }

    /// Extract the first meaningful line from devotional markdown, stripped of formatting.
    private func extractTeaser(from message: String) -> String? {
        let cleaned = message
            .replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: "#", with: "")

        let lines = cleaned.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 20 {
                if trimmed.count > 150 {
                    let index = trimmed.index(trimmed.startIndex, offsetBy: 147)
                    return String(trimmed[..<index]) + "..."
                }
                return trimmed
            }
        }

        return nil
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

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
    static let onboardingReplayRequested = Notification.Name("onboardingReplayRequested")
}
