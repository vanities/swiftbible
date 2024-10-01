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
    @State private var selectedTab: Tabs = .bible

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Bible", systemImage: "book.fill", value: .bible) {
                BibleView()
            }

            Tab("Daily Devotional", systemImage: "sun.horizon.fill", value: .dailyDevotional) {
                DailyDevotionalView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchDetailView(selectedTab: $selectedTab)
            }

            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                SettingsView(selectedTab: $selectedTab)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
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
