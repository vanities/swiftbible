//
//  AppViewModel.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import SwiftUI

struct SelectedVerse {
    var book: Book
    var chapter: Chapter
    var verse: Int
}

@Observable
class AppViewModel {
    var showSelectedVerse: Bool = false
    var selectedVerse: SelectedVerse?
    var allBibleData: [Book]?
    var navigationPath = NavigationPath()

    func navigateToVerse(bookName: String, chapterNumber: Int, verseNumber: Int) {
        guard let books = allBibleData,
              let book = books.first(where: { $0.name == bookName }),
              let chapter = book.chapters.first(where: { $0.number == chapterNumber })
        else { return }
        selectedVerse = SelectedVerse(
            book: book,
            chapter: chapter,
            verse: verseNumber
        )
        showSelectedVerse = true
    }
}
