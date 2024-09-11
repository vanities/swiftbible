//
//  HighlightedColorView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/10/24.
//

import SwiftUI


struct ColorOptionsView: View {
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @AppStorage("notedColor") private var notedColor: String = "FFFFE0"
    @State private var highlightColor = Color.yellow
    @State private var noteColor = Color.yellow

    var body: some View {
        Form {
            Section(header: Text("Select Note Indicator Color")) {
                ColorPicker("Select Note Indicator Color", selection: $noteColor)
            }
            Section(header: Text("Select Highlighted Color")) {
                ColorPicker("Highlighted Color", selection: $highlightColor)
            }
        }
        .navigationBarTitle("Highlighted Color")
        .onAppear {
            highlightColor = Color(hex: highlightedColor)
            noteColor = Color(hex: notedColor)
        }
        .onChange(of: highlightColor) {
            highlightedColor = highlightColor.hexValue
        }
        .onChange(of: noteColor) {
            notedColor = noteColor.hexValue
        }
    }
}

#Preview {
    ColorOptionsView()
        .environment(UserViewModel())
}

