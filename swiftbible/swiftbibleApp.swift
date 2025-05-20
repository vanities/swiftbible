//
//  swiftbibleApp.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI

@main
struct swiftbibleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [HighlightedVerse.self, Note.self], isUndoEnabled: true)
    }
}
