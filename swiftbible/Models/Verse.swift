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
    var startingVerse: String

    init(id: String = UUID().uuidString, book: String, startingVerse: String) {
        self.id = id
        self.book = book
        self.startingVerse = startingVerse
    }
}

struct Verse: Hashable {
    let number: String?
    let text: String
}

