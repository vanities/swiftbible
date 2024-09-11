//
//  Note.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import SwiftUI
import SwiftData

@Model
final class Note: Identifiable {

    @Attribute(.unique) var id: String = UUID().uuidString
    var version: String
    var book: String
    var chapter: Int
    var startingVerse: Int
    var text: String
    var created: Date

    init(
        id: String = UUID().uuidString,
        version: String,
        book: String,
        chapter: Int,
        startingVerse: Int,
        text: String,
        created: Date = .init()
    ) {
        self.id = id
        self.version = version
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
        self.text = text
        self.created = created
    }
}
