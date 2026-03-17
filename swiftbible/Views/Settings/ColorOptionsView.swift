//
//  HighlightedColorView.swift
//  swiftbible
//
//  Created on 9/10/24.
//

import SwiftUI

struct ColorOptionsView: View {
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @AppStorage("notedColor") private var notedColor: String = "00ff04"
    @State private var highlightColor = Color.yellow
    @State private var noteColor = Color.yellow

    var body: some View {
        Form {
            Section(header: Text("Note Indicator Color")) {
                ColorPicker("Note Indicator Color", selection: $noteColor)
            }
            Section(header: Text("Highlight Color")) {
                ColorPicker("Highlight Color", selection: $highlightColor)
            }
        }
        .navigationBarTitle("Color Options")
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
}
