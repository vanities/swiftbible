//
//  HistoryModels.swift
//  swiftbible
//
//  Models for the History tab — sections, articles, body blocks,
//  pull quotes, and external sources.
//

import Foundation

struct HistorySection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let era: String
    let articles: [HistoryArticle]
}

struct HistoryArticle: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let era: String
    let estimatedMinutes: Int
    let body: [BodyBlock]
    let pullQuotes: [PullQuote]
    let sources: [HistorySource]
    let related: [String]
}

enum BodyBlock: Hashable {
    case paragraph(String)
    case heading(String)
    case quote(text: String, attribution: String)
    case list([String])
    case timeline([TimelineEntry])
    case divider
}

struct TimelineEntry: Hashable, Identifiable {
    let id = UUID()
    let year: String
    let event: String
}

struct PullQuote: Hashable, Identifiable {
    let id = UUID()
    let text: String
    let attribution: String
    let context: String?
}

struct HistorySource: Hashable, Identifiable {
    let id = UUID()
    let title: String
    let author: String?
    let kind: SourceKind
    let url: String?
    let note: String?
}

enum SourceKind: String, Hashable {
    case primary
    case scholarly
    case encyclopedia
    case scripture

    var label: String {
        switch self {
        case .primary: return "Primary"
        case .scholarly: return "Scholarly"
        case .encyclopedia: return "Reference"
        case .scripture: return "Scripture"
        }
    }
}
