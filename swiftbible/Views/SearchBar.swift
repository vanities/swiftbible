//
//  SearchBar.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")

            TextField("Search", text: $text)
                .foregroundColor(.primary)

            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10.0)
    }
}

#Preview {
    @Previewable @State var text: String = ""
    SearchBar(text: $text)
}
