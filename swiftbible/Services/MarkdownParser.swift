//
//  Markdown.swift
//  swiftbible
//
//  Created by Adam Mischke on 4/10/25.
//

import Foundation
import Ink

func markdownToPlainText(_ markdown: String) -> String {
    let parser = MarkdownParser()
    let html = parser.html(from: markdown)

    // Convert HTML to plain text using NSAttributedString
    guard let data = html.data(using: .utf8),
          let attributed = try? NSAttributedString(
              data: data,
              options: [
                  .documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue
              ],
              documentAttributes: nil
          )
    else {
        return markdown
    }

    return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
}
