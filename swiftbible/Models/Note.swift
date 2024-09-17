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
    var version: String = ""
    var book: String = ""
    var chapter: Int = 0
    var startingVerse: Int = 0
    var text: String = ""
    var created = Date()

    init(
        version: String,
        book: String,
        chapter: Int,
        startingVerse: Int,
        text: String,
        created: Date
    ) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.startingVerse = startingVerse
        self.text = text
        self.created = created
    }
}
