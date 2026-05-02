//
//  HistoryContent.swift
//  swiftbible
//
//  Top-level index of all history sections. Articles themselves live
//  in the per-section files (HistoryOrigins, HistoryEarlyChurch, ...).
//

import Foundation

enum HistoryContent {
    static let allSections: [HistorySection] = [
        .ancientIsrael,
        .intertestamental,
        .hebrewBible,
        .origins,
        .earlyChurch,
        .splits,
        .denominations,
        .practices,
        .further
    ]

    static func article(id: String) -> HistoryArticle? {
        for section in allSections {
            if let match = section.articles.first(where: { $0.id == id }) {
                return match
            }
        }
        return nil
    }

    static func section(forArticle id: String) -> HistorySection? {
        allSections.first { $0.articles.contains(where: { $0.id == id }) }
    }
}
