import Combine
import Foundation
import SwiftUI

/// Shared App Group — must match the iOS app and widget.
let appGroupID = "group.com.am2.swiftbible"

// Supabase REST (same as widget)
private let supabaseURL = "https://yvanxjoayoiocwzfpkfm.supabase.co"
private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YW54am9heW9pb2N3emZwa2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU0OTQ5NTcsImV4cCI6MjA0MTA3MDk1N30.gG7dCHItgIBQhjA4EK38FJ6ju-I7mSJlvJRzVLaPuOs"

/// Minimal Codable struct matching what the iOS app / widget writes to the shared container.
struct SharedDevotional: Codable {
    let message: String

    /// The watch fetches the Edge Function directly and also reads the shared
    /// container, so it strips `<JESUS>…</JESUS>` red-letter markup itself
    /// rather than rely on the phone having cleaned the text first.
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

/// The "Daily Devotional" table no longer allows direct anon/authenticated
/// PostgREST reads — devotionals are served by the get-daily-devotional Edge
/// Function, which allowlists the *app's* bundle id (com.vanities.swiftbible)
/// and validates DEVOTIONAL_READ_SECRET. The watch sends the app id and the
/// "ios" platform because that is what the Edge Function allowlists.
private let appBundleIdentifier = "com.vanities.swiftbible"

private func devotionalAppHeaders() -> [String: String] {
    var headers = [
        "x-swiftbible-platform": "ios",
        "x-swiftbible-bundle-id": appBundleIdentifier
    ]
    if let secret = devotionalReadSecret() {
        headers["x-swiftbible-client-key"] = secret
    }
    return headers
}

/// Reads DEVOTIONAL_READ_SECRET injected into the watch app's Info.plist at
/// build time. Returns nil when unresolved so we never send a literal "$(…)".
private func devotionalReadSecret() -> String? {
    guard let raw = Bundle.main.infoDictionary?["DEVOTIONAL_READ_SECRET"] as? String else {
        return nil
    }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, !value.hasPrefix("$(") else { return nil }
    return value
}

@MainActor
final class DevotionalStore: ObservableObject {
    @Published var markdown: String = ""
    @Published var dateLabel: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func load(force: Bool = false) async {
        if isLoading { return }
        isLoading = true
        defer { isLoading = false }

        dateLabel = Self.prettyDate(Date())

        if !force, let cached = Self.readFromAppGroup(date: Date()) {
            markdown = cached.message
            errorMessage = nil
            return
        }

        do {
            let fetched = try await Self.fetchFromSupabase(date: Date())
            Self.writeToAppGroup(fetched, date: Date())
            markdown = fetched.message
            errorMessage = nil
        } catch {
            if let cached = Self.readFromAppGroup(date: Date()) {
                markdown = cached.message
                errorMessage = nil
            } else {
                errorMessage = String(localized: "No devotional available. Try again later.")
            }
        }
    }

    // MARK: - Helpers

    static func prettyDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func fetchFromSupabase(date: Date) async throws -> SharedDevotional {
        let dateString = isoDate(date)
        guard let url = URL(string: "\(supabaseURL)/functions/v1/get-daily-devotional") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        for (field, value) in devotionalAppHeaders() {
            request.setValue(value, forHTTPHeaderField: field)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["forDate": dateString])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SharedDevotional.self, from: data)
    }

    static func readFromAppGroup(date: Date) -> SharedDevotional? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return nil }
        let fileURL = container
            .appendingPathComponent("Devotionals")
            .appendingPathComponent("\(isoDate(date)).json")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(SharedDevotional.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func writeToAppGroup(_ devotional: SharedDevotional, date: Date) {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }
        let dir = container.appendingPathComponent("Devotionals")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(isoDate(date)).json")
        if let data = try? JSONEncoder().encode(devotional) {
            try? data.write(to: fileURL)
        }
    }
}
