import WidgetKit
import SwiftUI

// MARK: - Shared Constants

/// App Group identifier — must match the App Group configured in both targets' entitlements.
/// Set this up in Xcode: Signing & Capabilities > App Groups > group.com.am2.swiftbible
let appGroupID = "group.com.am2.swiftbible"

// Supabase REST API for direct widget fetching
let supabaseURL = "https://yvanxjoayoiocwzfpkfm.supabase.co"
let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YW54am9heW9pb2N3emZwa2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ5NTcsImV4cCI6MjA0MTA3MDk1N30.gG7dCHItgIBQhjA4EK38FJ6ju-I7mSJlvJRzVLaPuOs"

/// The "Daily Devotional" table no longer allows direct anon/authenticated
/// PostgREST reads — devotionals are served by the get-daily-devotional Edge
/// Function, which allowlists the *app's* bundle id and validates
/// DEVOTIONAL_READ_SECRET. The widget extension's own bundle id
/// (…swiftbibleWidget) is rejected by the allowlist, so it sends the app id.
let appBundleIdentifier = "com.vanities.swiftbible"

/// Headers required by the get-daily-devotional Edge Function.
func devotionalAppHeaders() -> [String: String] {
    var headers = [
        "x-swiftbible-platform": "ios",
        "x-swiftbible-bundle-id": appBundleIdentifier
    ]
    if let secret = devotionalReadSecret() {
        headers["x-swiftbible-client-key"] = secret
    }
    return headers
}

/// Reads DEVOTIONAL_READ_SECRET injected into the extension's Info.plist at
/// build time (Secrets.xcconfig locally / Xcode Cloud env vars in CI). Returns
/// nil when unresolved so we never send a literal "$(…)" placeholder.
func devotionalReadSecret() -> String? {
    guard let raw = Bundle.main.infoDictionary?["DEVOTIONAL_READ_SECRET"] as? String else {
        return nil
    }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !value.hasPrefix("$(") else { return nil }
    return value
}

// MARK: - Entry

struct DevotionalEntry: TimelineEntry {
    let date: Date
    let title: String
    let heading: String?
    let preview: String
    let hasDevotional: Bool
}

// MARK: - Timeline Provider

struct DailyDevotionalProvider: TimelineProvider {
    func placeholder(in context: Context) -> DevotionalEntry {
        DevotionalEntry(
            date: Date(),
            title: String(localized: "Daily Devotional"),
            heading: String(localized: "A Word for Today"),
            preview: String(localized: "Open SwiftBible to read today's devotional and grow in scripture."),
            hasDevotional: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DevotionalEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DevotionalEntry>) -> Void) {
        // Try local cache first
        let cached = loadEntry()
        if cached.hasDevotional {
            let nextUpdate = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            )
            let timeline = Timeline(entries: [cached], policy: .after(nextUpdate))
            completion(timeline)
            return
        }

        // Cache miss — fetch from Supabase
        Task {
            let entry = await fetchFromSupabase() ?? cached
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
    }

    private func fetchFromSupabase() async -> DevotionalEntry? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())

        // Direct PostgREST reads of "Daily Devotional" are locked out, so go
        // through the get-daily-devotional Edge Function (same path the app uses).
        guard let url = URL(string: "\(supabaseURL)/functions/v1/get-daily-devotional") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        for (field, value) in devotionalAppHeaders() {
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["forDate": dateString])

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let devotional = try? JSONDecoder().decode(SharedDevotional.self, from: data) else {
            return nil
        }

        // Save to App Group container so it's cached for next refresh
        saveToSharedContainer(devotional, dateString: dateString)

        let preview = cleanMarkdown(devotional.message)
        let heading = extractHeading(devotional.message)
        return DevotionalEntry(
            date: Date(),
            title: devotionalTitle(for: Date()),
            heading: heading,
            preview: preview,
            hasDevotional: true
        )
    }

    private func saveToSharedContainer(_ devotional: SharedDevotional, dateString: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let dir = containerURL.appendingPathComponent("Devotionals")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(dateString).json")
        if let data = try? JSONEncoder().encode(devotional) {
            try? data.write(to: fileURL)
        }
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
        let heading = extractHeading(devotional.message)
        return DevotionalEntry(
            date: Date(),
            title: devotionalTitle(for: Date()),
            heading: heading,
            preview: preview,
            hasDevotional: true
        )
    }

    private func fallbackEntry() -> DevotionalEntry {
        DevotionalEntry(
            date: Date(),
            title: devotionalTitle(for: Date()),
            heading: nil,
            preview: String(localized: "Open SwiftBible to load today's devotional."),
            hasDevotional: false
        )
    }

    private func devotionalTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    /// Strip markdown formatting and extract body content for widget display
    private func cleanMarkdown(_ text: String) -> String {
        let clean = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "> ", with: "")
        // Split into paragraphs and skip the first (title/date/heading) line
        let paragraphs = clean.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        // Use second paragraph (body) if available, otherwise fall back to first
        let body = paragraphs.count > 1 ? paragraphs[1] : (paragraphs.first ?? clean)
        if body.count > 300 {
            let truncated = body.prefix(300)
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return String(truncated) + "..."
        }
        return body
    }

    /// Extract the devotional heading (first paragraph) for display
    private func extractHeading(_ text: String) -> String? {
        let clean = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
        let paragraphs = clean.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let first = paragraphs.first else { return nil }
        // Strip the date prefix (e.g. "March 30, 2026 — ") to keep it short
        if let dashRange = first.range(of: " — ") {
            return String(first[dashRange.upperBound...])
        }
        return first
    }
}

/// Minimal Codable struct matching what the main app writes to the shared container.
struct SharedDevotional: Codable {
    let message: String

    /// The shared container can hold text cached before the main app learned to
    /// strip `<JESUS>…</JESUS>` red-letter markup, so strip on read too rather
    /// than surface raw tags on the home screen.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .message)
        message = raw.replacingOccurrences(
            of: "</?JESUS>",
            with: "",
            options: .regularExpression
        )
    }
}

// MARK: - Widget Views

struct DevotionalSmallView: View {
    let entry: DevotionalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                .lineLimit(6)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Text(entry.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(0)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct DevotionalMediumView: View {
    let entry: DevotionalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "sun.horizon.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(entry.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let heading = entry.heading {
                Text(heading)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .lineLimit(2)
            }

            Text(entry.preview)
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(0)
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
        heading: "Psalm 23: The Lord Is My Shepherd",
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
        heading: "Holy Monday — Matthew 21:13: A House of Prayer, Cleansed by Christ",
        preview: "In Psalm 23, David paints a picture of God as a shepherd who provides, protects, and guides. Even in the darkest valleys, we need not fear — for God's rod and staff bring comfort and direction.",
        hasDevotional: true
    )
}
