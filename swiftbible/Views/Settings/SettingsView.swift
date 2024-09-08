//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI


struct SettingsView: View {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?


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

