//
//  ParagraphParser.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/9/24.
//

import Foundation

class ParagraphParser {
    static func parse(_ paragraph: String) -> [Verse] {
        let pattern = #"\b(\d+:\d+)\b"#
        let regex = try! NSRegularExpression(pattern: pattern)

        let matches = regex.matches(in: paragraph, range: NSRange(paragraph.startIndex..., in: paragraph))

        var result: [Verse] = []
        var startIndex = paragraph.startIndex

        for match in matches {
            let endIndex = match.range.location
            let text = String(paragraph[startIndex..<paragraph.index(paragraph.startIndex, offsetBy: endIndex)].trimmingCharacters(in: .whitespaces))
            result.append(Verse(number: nil, text: text))

            let verseNumber = String(paragraph[Range(match.range, in: paragraph)!])
            let components = verseNumber.split(separator: ":")
            if components.count == 2 {
                result.append(Verse(number: Int(components[1]), text: ""))
            }

            startIndex = paragraph.index(paragraph.startIndex, offsetBy: match.range.location + match.range.length)
        }

        let remainingText = String(paragraph[startIndex...].trimmingCharacters(in: .whitespaces))
        result.append(Verse(number: nil, text: remainingText))
        return result
    }
}

