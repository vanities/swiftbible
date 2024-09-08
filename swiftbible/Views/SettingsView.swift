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
                        .keyboardType(.emailAddress)
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

struct SettingsView: View {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?

    @Environment(UserViewModel.self) private var userViewModel

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

struct SignInView: View {
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
                        .keyboardType(.emailAddress)
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
        .navigationBarTitle("Sign In")
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

struct FontSizeView: View {
    @AppStorage("fontSize") private var fontSize: CGFloat = 14

    var body: some View {
        Form {
            Section(header: Text("Font Size")) {
                Slider(value: $fontSize, in: 10...24, step: 1) {
                    Text("Font Size: \(Int(fontSize))")
                }
            }
        }
        .navigationBarTitle("Font Size")
    }
}
