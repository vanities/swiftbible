//
//  ReadingSession.swift
//  swiftbible
//

import Foundation
import SwiftData

@Model
class ReadingSession {
    var bookName: String = ""
    var chapterNumber: Int = 0
    var version: String = "kjv"
    var startedAt: Date = Date()
    var duration: TimeInterval = 0
    var date: Date = Date()
    // True once the reader scrolled to the last verse of this chapter. Combined
    // with a ≥30s dwell it marks the chapter "read" (see readChapterNumbers).
    // Defaulted (no unique) to stay CloudKit-compatible.
    var reachedEnd: Bool = false

    init(bookName: String, chapterNumber: Int, version: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.version = version
        self.startedAt = Date()
        self.duration = 0
        self.date = Calendar.current.startOfDay(for: Date())
    }
}
