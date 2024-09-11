//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI


struct SettingsView: View {
    @Environment(UserViewModel.self) private var userViewModel

    var body: some View {
        @Bindable var userViewModel = userViewModel

        NavigationStack {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: AuthenticateView()) {
                        Label("Authenticate", systemImage: "person.circle")
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
            .navigationDestination(
                isPresented: $userViewModel.showSignInFlow,
                destination: {
                    AuthenticateView()
                }
            )
        }
    }
}

#Preview {
    SettingsView()
        .environment(UserViewModel())
}

