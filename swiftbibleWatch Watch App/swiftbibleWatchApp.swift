//
//  swiftbibleWatchApp.swift
//  swiftbibleWatch Watch App
//
//  Created by Adam Mischke on 4/12/26.
//

import SwiftUI

@main
struct swiftbibleWatch_Watch_AppApp: App {
    @StateObject private var store = DevotionalStore()

    init() {
        ReminderScheduler.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                DevotionalView()
                    .environmentObject(store)
                    .task { await store.load() }
            }
        }
    }
}
