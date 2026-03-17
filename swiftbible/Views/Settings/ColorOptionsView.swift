//
//  HighlightedColorView.swift
//  swiftbible
//
//  Created on 9/10/24.
//

import SwiftUI

struct ColorOptionsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @AppStorage("notedColor") private var notedColor: String = "00ff04"
    @AppStorage("customAccentColor") private var customAccentHex: String = ""
    @State private var highlightColor = Color.yellow
    @State private var noteColor = Color.yellow
    @State private var accentColor = Color.brandAccent

    private var canCustomizeAccent: Bool {
        #if DEBUG
        return true
        #else
        return appViewModel.totalPaidCents > 0 || userViewModel.isAdmin
        #endif
    }

    var body: some View {
        Form {
            Section(header: Text("Note Indicator Color")) {
                ColorPicker("Note Indicator Color", selection: $noteColor)
            }
            Section(header: Text("Highlight Color")) {
                ColorPicker("Highlight Color", selection: $highlightColor)
            }

            if canCustomizeAccent {
                Section(
                    header: Text("Accent Color"),
                    footer: Text("Thank you for donating! Choose a custom accent color for the app.")
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
        }
        .navigationBarTitle("Color Options")
        .onAppear {
            highlightColor = Color(hex: highlightedColor)
            noteColor = Color(hex: notedColor)
            if !customAccentHex.isEmpty {
                accentColor = Color(hex: customAccentHex)
            }
        }
        .onChange(of: highlightColor) {
            highlightedColor = highlightColor.hexValue
        }
        .onChange(of: noteColor) {
            notedColor = noteColor.hexValue
        }
        .onChange(of: accentColor) {
            customAccentHex = accentColor.hexValue
        }
    }
}

#Preview {
    ColorOptionsView()
        .environment(UserViewModel())
}
