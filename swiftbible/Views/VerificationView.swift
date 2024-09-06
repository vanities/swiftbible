//
//  VerificationView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI

struct VerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserViewModel.self) private var userViewModel

    let email: String

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
            try await SupabaseService.shared.verifyOTP(email: email, verificationCode: verificationCode)
            userViewModel.user = await SupabaseService.shared.getUser()
            dismiss()
        } catch {
            errorMessage = "Verification error: \(error.localizedDescription)"
        }
    }
}
