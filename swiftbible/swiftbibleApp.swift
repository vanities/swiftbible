//
//  swiftbibleApp.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI

@main
struct swiftbibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(for: [HighlightedVerse.self, Note.self, SavedDevotional.self], isUndoEnabled: true)
    }
}
