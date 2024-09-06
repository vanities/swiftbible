//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?

    @Environment(UserViewModel.self) private var userViewModel

    @State private var email = ""
    @State private var verificationCode = ""
    @State private var showVerificationView = false

    var body: some View {
        Form {
            Section(header: Text("Supabase Authentication")) {
                if let user = userViewModel.user {
                    Text("Signed in as: \(user.email ?? "")")
                    Button("Sign Out") {
                        Task {
                            await signOut()
                        }
                    }
                } else {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button("Sign In") {
                        Task {
                            await SupabaseService.shared.signIn(email: email)
                            showVerificationView = true
                        }
                    }
                    .sheet(isPresented: $showVerificationView) {
                        VerificationView(email: email)
                    }
                }
            }
        }
        .navigationBarTitle("Settings")
    }

    private func signOut() async {
        do {
            try await SupabaseService.shared.auth.signOut()
            email = ""
            userViewModel.user = nil
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
}
