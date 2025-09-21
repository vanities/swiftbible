//
//  VerseExplanationRequest.swift
//  swiftbible
//
//  Created by OpenAI.
//

import Foundation

struct VerseExplanationRequest: Identifiable, Equatable {
    let id = UUID()
    let bookName: String
    let chapter: Int
    let startingVerse: Int
    let translation: String
    let paragraphText: String

    var reference: String {
        "\(bookName) \(chapter):\(startingVerse)"
    }

    var cleanedVerseText: String {
        let withoutTags = paragraphText
            .replacingOccurrences(of: "<JESUS>", with: "")
            .replacingOccurrences(of: "</JESUS>", with: "")
        let withoutNumbers = withoutTags.replacingOccurrences(
            of: #"\b\d+:\d+\b"#,
            with: "",
            options: .regularExpression
        )
        return withoutNumbers
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var userPrompt: String {
        """
        Provide a thoughtful and pastorally helpful explanation for the Bible passage \(reference) from the \(translation.uppercased()) translation. Keep the tone warm, encouraging, and grounded in orthodox Christian theology. Incorporate historical and literary context when helpful, highlight the main takeaway, and offer a gentle suggestion for application today.

        Passage Text:
        \(cleanedVerseText)
        """
    }
}
