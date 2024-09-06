//
//  ContentView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI

struct ContentView: View {
    @State private var userViewModel = UserViewModel()

    var body: some View {
        TabView {
            Tab("Bible", systemImage: "tray.and.arrow.down.fill") {
                BibleView()
            }
            Tab("Settings", systemImage: "person.crop.circle.fill") {
                SettingsView()
            }
        }
        .onAppear {
            Task {
                await SupabaseService.shared.refreshToken()
                userViewModel.user = await SupabaseService.shared.getUser()
            }
        }
        .environment(userViewModel)
    }
}

#Preview {
    ContentView()
}
