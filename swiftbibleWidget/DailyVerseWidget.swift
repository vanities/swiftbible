import WidgetKit
import SwiftUI

// MARK: - Shared Constants

/// App Group identifier — must match the App Group configured in both targets' entitlements.
/// Set this up in Xcode: Signing & Capabilities > App Groups > group.com.am2.swiftbible
let appGroupID = "group.com.am2.swiftbible"

// MARK: - Entry

struct DevotionalEntry: TimelineEntry {
    let date: Date
    let title: String
    let preview: String
    let hasDevotional: Bool
}

// MARK: - Timeline Provider

struct DailyDevotionalProvider: TimelineProvider {
    func placeholder(in context: Context) -> DevotionalEntry {
        DevotionalEntry(
            date: Date(),
            title: "Daily Devotional",
            preview: "Open SwiftBible to read today's devotional and grow in scripture.",
            hasDevotional: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DevotionalEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DevotionalEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh at midnight or in 1 hour if no devotional found
        let nextUpdate: Date
        if entry.hasDevotional {
            nextUpdate = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            )
        } else {
            nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        }
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> DevotionalEntry {
        // Try to read today's devotional from the shared App Group container
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            return fallbackEntry()
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let fileURL = containerURL
            .appendingPathComponent("Devotionals")
            .appendingPathComponent("\(dateString).json")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let devotional = try? JSONDecoder().decode(SharedDevotional.self, from: data) else {
            return fallbackEntry()
        }

        let preview = cleanMarkdown(devotional.message)
        return DevotionalEntry(
            date: Date(),
            title: devotionalTitle(for: Date()),
            preview: preview,
            hasDevotional: true
        )
    }

    private func fallbackEntry() -> DevotionalEntry {
        DevotionalEntry(
            date: Date(),
            title: devotionalTitle(for: Date()),
            preview: "Open SwiftBible to load today's devotional.",
            hasDevotional: false
        )
    }

    private func devotionalTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    /// Strip markdown formatting for widget display
    private func cleanMarkdown(_ text: String) -> String {
        var clean = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "> ", with: "")
        // Take first meaningful paragraph
        let paragraphs = clean.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        clean = paragraphs.first ?? clean
        if clean.count > 200 {
            let truncated = clean.prefix(200)
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return String(truncated) + "..."
        }
        return clean
    }
}

/// Minimal Codable struct matching what the main app writes to the shared container.
struct SharedDevotional: Codable {
    let message: String
}

// MARK: - Widget Views

struct DevotionalSmallView: View {
    let entry: DevotionalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sun.horizon.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("Devotional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(entry.preview)
                .font(.system(size: 12, design: .serif))
                .lineLimit(5)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text(entry.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct DevotionalMediumView: View {
    let entry: DevotionalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.horizon.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text(entry.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !entry.hasDevotional {
                    Text("Tap to load")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(entry.preview)
                .font(.system(size: 14, design: .serif))
                .lineLimit(4)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            if entry.hasDevotional {
                Text("Read more in SwiftBible")
                    .font(.caption2)
                    .foregroundStyle(.accent)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget Definition

struct DailyVerseWidget: Widget {
    let kind: String = "DailyDevotionalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyDevotionalProvider()) { entry in
            DailyDevotionalEntryView(entry: entry)
                .widgetURL(URL(string: "swiftbible://devotional"))
        }
        .configurationDisplayName("Daily Devotional")
        .description("Today's devotional from SwiftBible.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyDevotionalEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: DevotionalEntry

    var body: some View {
        switch family {
        case .systemSmall:
            DevotionalSmallView(entry: entry)
        case .systemMedium:
            DevotionalMediumView(entry: entry)
        default:
            DevotionalSmallView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    DailyVerseWidget()
} timeline: {
    DevotionalEntry(
        date: Date(),
        title: "Thursday, Mar 27",
        preview: "In Psalm 23, David paints a picture of God as a shepherd who provides, protects, and guides. Even in the darkest valleys, we need not fear.",
        hasDevotional: true
    )
}

#Preview(as: .systemMedium) {
    DailyVerseWidget()
} timeline: {
    DevotionalEntry(
        date: Date(),
        title: "Thursday, Mar 27",
        preview: "In Psalm 23, David paints a picture of God as a shepherd who provides, protects, and guides. Even in the darkest valleys, we need not fear — for God's rod and staff bring comfort and direction.",
        hasDevotional: true
    )
}
