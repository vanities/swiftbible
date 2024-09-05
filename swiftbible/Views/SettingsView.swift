//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @State private var isSignedIn = false
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var showVerificationView = false

    var body: some View {
        Form {
            Section(header: Text("Supabase Authentication")) {
                if isSignedIn {
                    Text("Signed in as: \(email)")
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
                            await signIn()
                            showVerificationView = true
                        }
                    }
                    .sheet(isPresented: $showVerificationView) {
                        VerificationView(email: email, isSignedIn: $isSignedIn)
                    }
                }
            }
        }
        .navigationBarTitle("Settings")
        .onAppear {
            //checkAuthStatus()
        }
    }

    private func signIn() async {
        do {
            try await SupabaseService.shared.auth.signInWithOTP(email: email)
        } catch {
            print("Sign-in error: \(error.localizedDescription)")
        }
    }

    private func signOut() async {
        do {
            try await SupabaseService.shared.auth.signOut()
            print("Sign-out successful.")
            removeToken()
            isSignedIn = false
            email = ""
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }

    private func retrieveToken() -> String? {
        return UserDefaults.standard.string(forKey: "supabaseToken")
    }

    private func removeToken() {
        UserDefaults.standard.removeObject(forKey: "supabaseToken")
    }
}

#Preview {
    SettingsView()
}
