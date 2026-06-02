//
//  SearchBar.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

    /// A subtle tint over the themed surface so the field still reads as a field
    /// (rather than a system grey rectangle floating on the sepia background).
    private var fieldBackground: Color {
        readingTheme.isCustom
            ? readingTheme.secondaryTextColor(for: colorScheme).opacity(0.15)
            : Color(.secondarySystemBackground)
    }

    private var accentText: Color {
        readingTheme.isCustom ? readingTheme.secondaryTextColor(for: colorScheme) : .secondary
    }

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Search", text: $text)
                .foregroundColor(readingTheme.isCustom ? readingTheme.textColor(for: colorScheme) : .primary)

            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(accentText)
        .background(fieldBackground)
        .cornerRadius(10.0)
    }
}

#Preview {
    SearchBar(text: .constant("James"))
}
