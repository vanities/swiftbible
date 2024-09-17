//
//  SignInView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/8/24.
//

import SwiftUI


struct AuthenticateView: View {
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var showVerificationView = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    @Environment(UserViewModel.self) private var userViewModel
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?

    var body: some View {
        Form {
            Section(header: Text("Supabase Authentication")) {
                if let user = userViewModel.user {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Signed in as: \(user.email ?? "")")
                            .font(.headline)

                        Button("Sign Out") {
                            Task {
                                await signOut()
                            }
                        }
                        .disabled(isDeleting)
                        .padding(.top, 5)

                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Account")
                                .foregroundColor(.red)
                        }
                        .padding(.top, 5)
                        .alert(isPresented: $showDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Account"),
                                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    Task {
                                        await deleteAccount()
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                } else {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button("Create Account / Sign In") {
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
        .navigationBarTitle("Authenticate")
    }

    private func signOut() async {
        do {
            try await SupabaseService.shared.auth.signOut()
            // Clear stored tokens
            supabaseAccessToken = nil
            supabaseRefreshToken = nil
            email = ""
            userViewModel.user = nil
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            let _ = try await SupabaseService.shared.client.functions.invoke("user-self-deletion")
            // Clear stored tokens and user data
            supabaseAccessToken = nil
            supabaseRefreshToken = nil
            email = ""
            userViewModel.user = nil
            print("Account successfully deleted.")
        } catch {
            print("Delete account error: \(error.localizedDescription)")
        }
        isDeleting = false
    }
}

#Preview {
    AuthenticateView()
        .environment(UserViewModel())
}


