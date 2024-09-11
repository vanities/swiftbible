//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI


struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: SignInView()) {
                        Label("Sign In", systemImage: "person.circle")
                    }
                }

                Section(header: Text("Appearance")) {
                    NavigationLink(destination: FontSizeView()) {
                        Label("Font Size", systemImage: "textformat.size")
                    }
                    NavigationLink(destination: HighlightedColorView()) {
                        Label("Highlighted Color", systemImage: "highlighter")
                    }
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(UserViewModel())
}

