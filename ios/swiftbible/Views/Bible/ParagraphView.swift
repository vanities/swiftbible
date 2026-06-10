//
//  VerseView.swift
//  swiftbible
//
//  Created on 9/6/24.
//

import SwiftUI

struct ParagraphView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true

    let firstVerseNumber: Int
    let verses: [Verse]
    let themeSecondaryColor: Color?

    init(firstVerseNumber: Int, paragraph: String, themeSecondaryColor: Color? = nil) {
        self.firstVerseNumber = firstVerseNumber
        self.verses = ParagraphParser.parse(paragraph)
        self.themeSecondaryColor = themeSecondaryColor
    }

    var body: some View {
        verseText()
    }

    func verseText() -> Text {
        verses.reduce(Text(verbatim: "")) { acc, verse in
            acc + numberPrefix(for: verse) + segmentsText(for: verse)
        }
    }

    /// Superscript styling shared by the verse number, its suffix, and the
    /// trailing spacer.
    private func verseNumberStyled(_ text: Text) -> Text {
        text
            .foregroundColor(themeSecondaryColor ?? .gray)
            .font(.footnote)
            .baselineOffset(6.0)
    }

    private func numberPrefix(for verse: Verse) -> Text {
        guard let number = verse.number else { return Text(verbatim: "") }
        let numberText = verseNumberStyled(Text(" \(number)"))
        let withSuffix = verse.suffix.map { numberText + verseNumberStyled(Text($0)) } ?? numberText
        return withSuffix + verseNumberStyled(Text(verbatim: " "))
    }

    private func segmentsText(for verse: Verse) -> Text {
        verse.segments.reduce(Text(verbatim: "")) { acc, segment in
            switch segment {
            case .regular(let text):
                return acc + Text(text)
                    .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
            case .jesus(let text):
                return acc + Text(text)
                    .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
                    .foregroundColor(showJesusWordsInRed ? .brandRed : .primary)
            }
        }
    }
}

#Preview {
    ParagraphView(
        firstVerseNumber: 13,
        paragraph: "And when he went out the second day, behold, two men of the Hebrews strove together: and he said to him that did the wrong, Wherefore smitest thou thy fellow? 2:14 And he said, Who made thee a prince and a judge over us? intendest thou to kill me, as thou killedst the Egyptian? And Moses feared, and said, Surely this thing is known."
    )
}
