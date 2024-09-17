//
//  Verse.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/9/24.
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

    init(
        version: String,
        book: String,
        chapter: Int,
        startingVerse: Int,
        created: Date = .init()
    ) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
        self.created = created
    }
}

struct Verse: Hashable {
    let number: Int?
    let text: String
}

