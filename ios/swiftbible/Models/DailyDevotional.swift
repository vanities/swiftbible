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

struct DailyDevotional: Codable {
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

extension String {
    /// bible.json marks Jesus's words with `<JESUS>…</JESUS>` for red-letter
    /// rendering. Devotional text is generated server-side from those verses,
    /// so a generator regression can inline the raw tags into the published
    /// message — readers then see `"<JESUS>I am that bread of life. </JESUS>"`.
    /// Stripping at decode keeps any such leak, past or future, off the screen.
    ///
    /// Only the tags go — never the whitespace hugging them. 418 KJV paragraphs
    /// carry an inline verse number between two tags (`…against thee;
    /// </JESUS>5:24<JESUS> Leave there…`), so eating the adjacent space would
    /// run words and verse numbers together.
    func strippingRedLetterTags() -> String {
        guard contains("JESUS>") else { return self }
        return replacingOccurrences(
            of: "</?JESUS>",
            with: "",
            options: .regularExpression
        )
    }
}

extension DailyDevotional {
    enum CodingKeys: String, CodingKey {
        case id, message, for_date, devotional_type, series_name, series_part
        case holiday_name, holiday_url, anchor_verse, verses, model, track
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        message = try container.decode(String.self, forKey: .message)
            .strippingRedLetterTags()
        for_date = try container.decode(String.self, forKey: .for_date)
        devotional_type = try container.decodeIfPresent(String.self, forKey: .devotional_type)
        series_name = try container.decodeIfPresent(String.self, forKey: .series_name)
        series_part = try container.decodeIfPresent(Int.self, forKey: .series_part)
        holiday_name = try container.decodeIfPresent(String.self, forKey: .holiday_name)
        holiday_url = try container.decodeIfPresent(String.self, forKey: .holiday_url)
        anchor_verse = try container.decodeIfPresent(String.self, forKey: .anchor_verse)
        verses = try container.decodeIfPresent([DevotionalVerse].self, forKey: .verses)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        track = try container.decodeIfPresent(String.self, forKey: .track)
    }
}
