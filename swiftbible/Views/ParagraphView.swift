//
//  VerseView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI

struct Verse: Hashable {
    let number: String?
    let text: String
}

struct ParagraphView: View {
    let paragraph: String

    var body: some View {
        parseVerses()
    }

    func parseVerses() -> Text {
        let pattern = #"\b(\d+:\d+)\b"#
        let regex = try! NSRegularExpression(pattern: pattern)

        let matches = regex.matches(in: paragraph, range: NSRange(paragraph.startIndex..., in: paragraph))

        var result: [(number: String?, text: String)] = []
        var startIndex = paragraph.startIndex

        for match in matches {
            let endIndex = match.range.location
            let text = String(paragraph[startIndex..<paragraph.index(paragraph.startIndex, offsetBy: endIndex)].trimmingCharacters(in: .whitespaces))
            result.append((number: nil, text: text))

            let verseNumber = String(paragraph[Range(match.range, in: paragraph)!])
            let components = verseNumber.split(separator: ":")
            if components.count == 2 {
                result.append((number: String(components[1]), text: ""))
            }

            startIndex = paragraph.index(paragraph.startIndex, offsetBy: match.range.location + match.range.length)
        }

        let remainingText = String(paragraph[startIndex...].trimmingCharacters(in: .whitespaces))
        result.append((number: nil, text: remainingText))
        print(result)

        return result.reduce(Text(""), {
            $0
            + Text("\($1.number != nil ? " \($1.number!)" : "")")
                .foregroundStyle(.gray)
                .font(.footnote)
                .baselineOffset(6.0)
            + Text("\($1.text) ")}
        )
    }
}
#Preview {
    ParagraphView(paragraph: "And when he went out the second day, behold, two men of the Hebrews strove together: and he said to him that did the wrong, Wherefore smitest thou thy fellow? 2:14 And he said, Who made thee a prince and a judge over us? intendest thou to kill me, as thou killedst the Egyptian? And Moses feared, and said, Surely this thing is known.")
}
