import AppIntents

struct SwiftBibleShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenDailyDevotionalIntent(),
            phrases: [
                "Open today's devotional in \(.applicationName)",
                "Read today's devotional in \(.applicationName)",
                "Daily devotional in \(.applicationName)"
            ],
            shortTitle: "Daily Devotional",
            systemImageName: "sun.horizon.fill"
        )
        AppShortcut(
            intent: OpenRandomVerseIntent(),
            phrases: [
                "Inspire me with a verse in \(.applicationName)",
                "Random verse in \(.applicationName)",
                "Open a random verse in \(.applicationName)"
            ],
            shortTitle: "Random Verse",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OpenBookIntent(),
            phrases: [
                "Open \(\.$book) in \(.applicationName)",
                "Read \(\.$book) in \(.applicationName)"
            ],
            shortTitle: "Open Book",
            systemImageName: "book.fill"
        )
    }
}
