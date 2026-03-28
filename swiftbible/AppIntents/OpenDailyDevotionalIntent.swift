import AppIntents

struct OpenDailyDevotionalIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Daily Devotional"
    static var description: IntentDescription = "Opens today's daily devotional in SwiftBible."
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .devotionalReminderTapped, object: nil)
        return .result()
    }
}
