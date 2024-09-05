//
//  VerificationView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI

struct VerificationView: View {
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

    private func saveToken(token: String) {
        UserDefaults.standard.set(token, forKey: "supabaseToken")
    }

    private func verify() async {
        do {
            let authResponse = try await SupabaseService.shared.auth.verifyOTP(email: email, token: verificationCode, type: .email)
            guard let session = authResponse.session else {
                print("Wrong verify")
                return
            }
            print("Sign-in successful. Token: \(String(describing: session.accessToken))")
            saveToken(token: session.accessToken)
            isSignedIn = true
            dismiss()
        } catch {
            print("Sign-in error: \(error.localizedDescription)")
            errorMessage = "Verification error: \(error.localizedDescription)"
        }
    }
}
