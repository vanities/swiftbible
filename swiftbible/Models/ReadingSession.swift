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

    init(bookName: String, chapterNumber: Int, version: String) {
        self.bookName = bookName
        self.chapterNumber = chapterNumber
        self.version = version
        self.startedAt = Date()
        self.duration = 0
        self.date = Calendar.current.startOfDay(for: Date())
    }
}
