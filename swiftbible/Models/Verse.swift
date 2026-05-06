//
//  Verse.swift
//  swiftbible
//
//  Created on 9/9/24.
//

import SwiftUI
import SwiftData

@Model
final class HighlightedVerse: Identifiable {
    var version: String = ""
    var book: String = ""
    var chapter: Int = 0
    var startingVerse: Int = 0
    var created = Date()
    var color: String = ""

    init(
        version: String,
        book: String,
        chapter: Int,
        startingVerse: Int,
        color: String = "",
        created: Date = .init()
    ) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
        self.color = color
        self.created = created
    }
}

struct Verse: Identifiable {
    let id = UUID()
    let number: Int?
    let suffix: String?
    let segments: [TextSegment]
}

enum TextSegment {
    case regular(String)
    case jesus(String)
}
