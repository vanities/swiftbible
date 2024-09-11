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
    var book: String
    var chapter: Int
    var startingVerse: Int

    init(
        id: String = UUID().uuidString,
        book: String,
        chapter: Int,
        startingVerse: Int
    ) {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
    }
}

struct Verse: Hashable {
    let number: Int?
    let text: String
}

