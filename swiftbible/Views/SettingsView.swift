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

    @State private var isSignedIn = false
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var showVerificationView = false
    @State private var user: User?

    var body: some View {
        Form {
            Section(header: Text("Supabase Authentication")) {
                if let user {
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
        .onChange(of: isSignedIn) {
            if isSignedIn {
                Task {
                    user = await SupabaseService.shared.getUser()
                }
            }
        }
        .onAppear {
            Task {
                user = await SupabaseService.shared.getUser()
            }
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
            removeAuth()
            isSignedIn = false
            email = ""
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }

    private func removeAuth() {
        supabaseAccessToken = ""
        supabaseRefreshToken = ""
    }
}

#Preview {
    SettingsView()
}
