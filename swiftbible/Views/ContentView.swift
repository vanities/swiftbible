//
//  ContentView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var appViewModel = AppViewModel()
    @State private var userViewModel = UserViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Bible", systemImage: "book.fill", value: 0) {
                BibleView()
            }
            Tab("Daily Devotional", systemImage: "sun.horizon.fill", value: 1) {
                DailyDevotionalView(selectedTab: $selectedTab)
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsView(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            Task {
                await SupabaseService.shared.refreshToken()
                userViewModel.user = await SupabaseService.shared.getUser()
            }
        }
        .environment(appViewModel)
        .environment(userViewModel)
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
        .environment(UserViewModel())
}
