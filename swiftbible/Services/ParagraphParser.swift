//
//  ParagraphParser.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/9/24.
//

import Foundation


class ParagraphParser {
    static func parse(_ paragraph: String) -> [Verse] {
        // Regex to identify verse numbers in the format "1:2", "1:3", etc.
        let versePattern = #"\b(\d+:\d+)\b"#
        let verseRegex = try! NSRegularExpression(pattern: versePattern, options: [])

        // Regex to identify <JESUS> and </JESUS> tags
        let jesusPattern = #"<JESUS>(.*?)<\/JESUS>"#
        let jesusRegex = try! NSRegularExpression(pattern: jesusPattern, options: .dotMatchesLineSeparators)

        let matches = verseRegex.matches(in: paragraph, range: NSRange(paragraph.startIndex..., in: paragraph))

        var result: [Verse] = []
        var startIndex = paragraph.startIndex

        for match in matches {
            // Range of the verse number (e.g., "1:2")
            guard let range = Range(match.range, in: paragraph) else { continue }
            let verseNumber = String(paragraph[range])

            // Text before the verse number
            let precedingText = String(paragraph[startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !precedingText.isEmpty {
                let segments = parseSegments(text: precedingText, regex: jesusRegex)
                result.append(Verse(number: nil, segments: segments))
            }

            // Extract verse number as Int (e.g., "1:2" -> 2)
            let components = verseNumber.split(separator: ":")
            var verseNum: Int? = nil
            if components.count == 2, let num = Int(components[1]) {
                verseNum = num
            }
            result.append(Verse(number: verseNum, segments: []))

            // Update startIndex to the end of the matched verse number
            startIndex = range.upperBound
        }

        // Remaining text after the last verse number
        let remainingText = String(paragraph[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !remainingText.isEmpty {
            let segments = parseSegments(text: remainingText, regex: jesusRegex)
            result.append(Verse(number: nil, segments: segments))
        }

        return result
    }

    private static func parseSegments(text: String, regex: NSRegularExpression) -> [TextSegment] {
        var segments: [TextSegment] = []
        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var currentLocation = 0

        for match in matches {
            let jesusRange = match.range(at: 1) // Capture group for Jesus's words
            if jesusRange.location > currentLocation {
                // Regular text before <JESUS> tag
                let regularText = nsText.substring(with: NSRange(location: currentLocation, length: jesusRange.location - currentLocation))
                segments.append(.regular(regularText.replacingOccurrences(of: "<JESUS>", with: "").replacingOccurrences(of: "</JESUS>", with: "")))
                // Optional: Uncomment for debugging
                // print("Regular Text: \(regularText)")
            }
            // Text within <JESUS> tags
            let jesusText = nsText.substring(with: jesusRange)
            segments.append(.jesus(jesusText))
            // Optional: Uncomment for debugging
            // print("Jesus Text: \(jesusText)")
            currentLocation = jesusRange.location + jesusRange.length
        }

        if currentLocation < nsText.length {
            // Remaining regular text after the last <JESUS> tag
            let remaining = nsText.substring(from: currentLocation)
            segments.append(.regular(remaining.replacingOccurrences(of: "<JESUS>", with: "").replacingOccurrences(of: "</JESUS>", with: "")))
            // Optional: Uncomment for debugging
            // print("Remaining Regular Text: \(remaining)")
        }

        return segments
    }
}
