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
                errorMessage = "No devotional available. Try again later."
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
        var components = URLComponents(string: "\(supabaseURL)/rest/v1/Daily Devotional")!
        components.queryItems = [
            URLQueryItem(name: "select", value: "message"),
            URLQueryItem(name: "for_date", value: "eq.\(dateString)")
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/vnd.pgrst.object+json", forHTTPHeaderField: "Accept")

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
