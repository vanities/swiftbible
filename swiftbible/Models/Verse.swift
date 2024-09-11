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

    @Attribute(.unique) var id: String = UUID().uuidString
    var version: String
    var book: String
    var chapter: Int
    var startingVerse: Int
    var created: Date

    init(
        id: String = UUID().uuidString,
        version: String,
        book: String,
        chapter: Int,
        startingVerse: Int,
        created: Date = .init()
    ) {
        self.id = id
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

