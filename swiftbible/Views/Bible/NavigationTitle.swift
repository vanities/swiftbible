//
//  NavigationTitle.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/13/24.
//

import SwiftUI

struct NavigationTitle: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    let name: String
    let description: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
            if let description {
                Text(description)
                    .font(.footnote)
                    .fontWeight(.light)
            } else {
                Text("")
            }
        }
        .font(Font.custom(fontName, size: CGFloat(fontSize)))
    }
}
