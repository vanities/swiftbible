//
//  HighlightedColorView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/10/24.
//

import SwiftUI


struct HighlightedColorView: View {
    @AppStorage("highlightedColor") private var highlightedColor: String = "FFFFE0"
    @State private var highlightColor = Color.yellow

    var body: some View {
        Form {
            Section(header: Text("Select Highlighted Color")) {
                ColorPicker("Highlighted Color", selection: $highlightColor)
            }
        }
        .navigationBarTitle("Highlighted Color")
        .onAppear {
            highlightColor = Color(hex: highlightedColor)
        }
        .onChange(of: highlightColor) {
            highlightedColor = highlightColor.hexValue
        }
    }
}

#Preview {
    HighlightedColorView()
        .environment(UserViewModel())
}

