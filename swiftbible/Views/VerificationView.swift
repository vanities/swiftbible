//
//  VerificationView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI

struct VerificationView: View {
    @AppStorage("supabaseAccessToken") private var supabaseAccessToken: String?
    @AppStorage("supabaseRefreshToken") private var supabaseRefreshToken: String?
    
    @Environment(\.dismiss) private var dismiss
    let email: String
    @Binding var isSignedIn: Bool
    @State private var verificationCode = ""
    @State private var errorMessage = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        Form {
            Section(header: Text("Verify Email")) {
                Text("Enter the verification code sent to \(email)")
                TextField("123456", text: $verificationCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                    .onChange(of: verificationCode) {
                        verificationCode = String(verificationCode.prefix(6))
                    }
                    .font(.system(.body, design: .monospaced))

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button("Verify") {
                    Task {
                        await verify()
                    }
                }
            }
        }
        .navigationBarTitle("Verification")
    }

    private func verify() async {
        do {
            /*
             {
               "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjI3MjkxNTc3LCJzdWIiOiJmYTA2NTQ1Zi1kYmI1LTQxY2EtYjk1NC1kOGUyOTg4YzcxOTEiLCJlbWFpbCI6IiIsInBob25lIjoiNjU4NzUyMjAyOSIsImFwcF9tZXRhZGF0YSI6eyJwcm92aWRlciI6InBob25lIn0sInVzZXJfbWV0YWRhdGEiOnt9LCJyb2xlIjoiYXV0aGVudGljYXRlZCJ9.1BqRi0NbS_yr1f6hnr4q3s1ylMR3c1vkiJ4e_N55dhM",
               "token_type": "bearer",
               "expires_in": 3600,
               "refresh_token": "LSp8LglPPvf0DxGMSj-vaQ",
               "user": {...}
             }
             */
            let authResponse = try await SupabaseService.shared.auth.verifyOTP(email: email, token: verificationCode, type: .email)
            guard let session = authResponse.session else {
                print("Wrong verify")
                return
            }
            print("Sign-in successful. Token: \(String(describing: session.accessToken))")
            supabaseAccessToken = session.accessToken
            supabaseRefreshToken = session.refreshToken
            isSignedIn = true
            dismiss()
        } catch {
            print("Sign-in error: \(error.localizedDescription)")
            errorMessage = "Verification error: \(error.localizedDescription)"
        }
    }
}
