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
}
