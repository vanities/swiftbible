//
//  DevotionalHistory.swift
//  swiftbible
//

import Foundation

/// Compact rolling log of devotional opens so the All Voices and Series
/// Completionist badges can evaluate against recent history without
/// reaching into PostHog. Records carry just enough metadata to support
/// the two queries; everything else is dropped.
struct DevotionalView: Codable, Equatable {
    let date: Date
    let track: String?
    let seriesName: String?
    let seriesPart: Int?
}

@MainActor
enum DevotionalHistory {
    private static let storageKey = "devotionalHistoryV1"
    private static let maxEntries = 200

    static func record(track: String?, seriesName: String?, seriesPart: Int?) {
        var history = load()
        history.append(DevotionalView(date: Date(), track: track, seriesName: seriesName, seriesPart: seriesPart))
        // Keep history bounded — enough for any "last N weeks" query, never
        // unbounded on heavy users.
        if history.count > maxEntries {
            history.removeFirst(history.count - maxEntries)
        }
        save(history)
    }

    static func load() -> [DevotionalView] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DevotionalView].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Distinct AI track names viewed in the trailing window.
    static func tracksInLast(days: Int) -> Set<String> {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return [] }
        return Set(load()
            .filter { $0.date >= cutoff }
            .compactMap { $0.track })
    }

    /// Series-name → set of parts the user has viewed. Used for the
    /// Series Completionist badge (parts 1..4 within one named series).
    static func seriesProgress() -> [String: Set<Int>] {
        var progress: [String: Set<Int>] = [:]
        for view in load() {
            guard let name = view.seriesName, let part = view.seriesPart else { continue }
            progress[name, default: []].insert(part)
        }
        return progress
    }

    private static func save(_ history: [DevotionalView]) {
        guard let encoded = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
