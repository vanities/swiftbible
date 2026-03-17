//
//  DonorPerksView.swift
//  swiftbible
//

import SwiftUI

struct DonorPerksView: View {
    @AppStorage("customAccentColor") private var customAccentHex: String = ""
    @State private var accentColor = Color.brandAccent

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Thank You", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Text("Your donation helps keep SwiftBible online and free for everyone. Here are some perks as a thank you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section(
                header: Text("Custom Accent Color"),
                footer: Text("Changes the color of toggles, links, and active tabs throughout the app.")
            ) {
                ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)

                if !customAccentHex.isEmpty {
                    Button("Reset to Default") {
                        accentColor = .brandAccent
                        customAccentHex = ""
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Donor Perks")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !customAccentHex.isEmpty {
                accentColor = Color(hex: customAccentHex)
            }
        }
        .onChange(of: accentColor) {
            customAccentHex = accentColor.hexValue
        }
    }
}

#Preview {
    NavigationStack {
        DonorPerksView()
    }
}
