//
//  SummariesService.swift
//  swiftbible
//
//  Created on 2026-04-14.
//
//  Loads chapter titles and passage summaries from per-source JSON files
//  bundled under swiftbible/Text/. Each source (SwiftBible Curated, Matthew
//  Henry's Concise Commentary) lives in its own file and is cached on first
//  access. Users select a source via the `summarySource` AppStorage key.
//
//  Sources that don't cover a particular book (e.g., Matthew Henry has no
//  entries for the Apocrypha, Enoch, or other pseudepigrapha) fall back to
//  the SwiftBible Curated source, so the picker never hides content — it
//  only changes the primary voice.
//

import Foundation

// MARK: - Summary source

enum SummarySource: String, CaseIterable, Identifiable {
    case matthewHenry = "mhcc"
    case jamiesonFaussetBrown = "jfb"
    case swiftBible = "swiftbible"
    case off = "off"

    var id: String { rawValue }

    /// Label shown in the Settings picker.
    var displayName: String {
        switch self {
        case .matthewHenry: return "Matthew Henry"
        case .jamiesonFaussetBrown: return "Jamieson-Fausset-Brown"
        case .swiftBible: return "SwiftBible Curated"
        case .off: return "Off"
        }
    }

    /// JSON resource filename (without extension), or nil for the off case.
    fileprivate var resourceName: String? {
        switch self {
        case .matthewHenry: return "summaries_mhcc"
        case .jamiesonFaussetBrown: return "summaries_jfb"
        case .swiftBible: return "summaries_swiftbible"
        case .off: return nil
        }
    }
}

// MARK: - Codable types matching the JSON schema

struct SummariesFile: Codable {
    let source: SummariesSourceInfo
    let chapterTitles: [String: [String: String]]
    let passageSummaries: [String: [String: [PassageSummaryEntry]]]
}

struct SummariesSourceInfo: Codable {
    let name: String
    let shortName: String
    let year: Int
    let license: String
    let attribution: String
}

struct PassageSummaryEntry: Codable {
    let startVerse: Int
    let endVerse: Int?
    let title: String
}

// MARK: - Service

final class SummariesService {
    static let shared = SummariesService()

    private var cache: [SummarySource: SummariesFile] = [:]

    private init() {}

    // MARK: File loading

    @discardableResult
    func load(_ source: SummarySource) -> SummariesFile? {
        if let cached = cache[source] { return cached }
        guard let resource = source.resourceName else { return nil }
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            print("SummariesService: missing bundle resource \(resource).json")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(SummariesFile.self, from: data)
            cache[source] = decoded
            return decoded
        } catch {
            print("SummariesService: failed to decode \(resource).json — \(error)")
            return nil
        }
    }

    // MARK: Lookups

    /// Returns the chapter title for a book/chapter under the selected source,
    /// falling back to the SwiftBible source if the primary doesn't cover it.
    /// Returns nil when the source is .off, or when no source has an entry.
    func chapterTitle(
        book: String,
        chapter: Int,
        source: SummarySource
    ) -> String? {
        guard source != .off else { return nil }

        let chapterKey = String(chapter)

        if let file = load(source),
           let title = file.chapterTitles[book]?[chapterKey],
           !title.isEmpty {
            return title
        }

        // Fallback to SwiftBible Curated if the primary source is something
        // else — covers pseudepigrapha, apocrypha, and the handful of
        // canonical chapters MHCC's outline parser couldn't extract.
        if source != .swiftBible,
           let fallback = load(.swiftBible),
           let title = fallback.chapterTitles[book]?[chapterKey],
           !title.isEmpty {
            return title
        }

        return nil
    }

    /// Returns the passage summary anchored at `startVerse` for the given
    /// chapter, or nil if no source has one. Used by ChapterDetailView to
    /// render the bold heading above a paragraph.
    func passageSummary(
        book: String,
        chapter: Int,
        startVerse: Int,
        source: SummarySource
    ) -> String? {
        guard source != .off else { return nil }

        let chapterKey = String(chapter)

        if let file = load(source),
           let entries = file.passageSummaries[book]?[chapterKey],
           let match = entries.first(where: { $0.startVerse == startVerse }) {
            return match.title
        }

        if source != .swiftBible,
           let fallback = load(.swiftBible),
           let entries = fallback.passageSummaries[book]?[chapterKey],
           let match = entries.first(where: { $0.startVerse == startVerse }) {
            return match.title
        }

        return nil
    }

    /// Attribution metadata for the given source, for display in Settings.
    func sourceInfo(_ source: SummarySource) -> SummariesSourceInfo? {
        load(source)?.source
    }
}

// MARK: - AppStorage default

/// Default value used by the @AppStorage("summarySource") binding on first
/// launch and in any view that reads the setting before a user has touched it.
/// Matthew Henry fills every blank left by the original hand-curated source,
/// so it's the better out-of-the-box experience.
let defaultSummarySource: SummarySource = .matthewHenry
