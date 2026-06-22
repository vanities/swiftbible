//
//  DailyDevotional.swift
//  swiftbible
//
//  Model representing a daily devotional message
//

import Foundation

struct DevotionalVerse: Codable, Equatable {
    let book: String
    let chapter: Int
    let verse: Int
    let testament: String
}

struct DailyDevotional: Codable, Equatable {
    let id: Int
    let message: String
    let for_date: String
    let devotional_type: String?
    let series_name: String?
    let series_part: Int?
    let holiday_name: String?
    let holiday_url: String?
    let anchor_verse: String?
    let verses: [DevotionalVerse]?
    let model: String?
    let track: String?
}

extension DailyDevotional {
    var cleanedForDisplay: DailyDevotional {
        DailyDevotional(
            id: id,
            message: message.removingRedLetterTags(),
            for_date: for_date,
            devotional_type: devotional_type,
            series_name: series_name,
            series_part: series_part,
            holiday_name: holiday_name,
            holiday_url: holiday_url,
            anchor_verse: anchor_verse,
            verses: verses,
            model: model,
            track: track
        )
    }
}

extension String {
    /// Removes red-letter markup from Bible text before that text is reused in
    /// prose contexts such as devotionals, notifications, and saved snippets.
    ///
    /// Bible paragraphs intentionally keep `<JESUS>` markers for red-letter
    /// rendering, but MarkdownUI displays those tags literally. The regex is
    /// intentionally narrow: it only strips opening/closing JESUS tags, while
    /// preserving the quoted words and all other devotional markdown.
    func removingRedLetterTags() -> String {
        replacingOccurrences(
            of: #"<\s*/?\s*JESUS\s*>"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }
}
