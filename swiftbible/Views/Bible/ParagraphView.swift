//
//  VerseView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI


struct ParagraphView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true

    let firstVerseNumber: Int
    let verses: [Verse]

    init(firstVerseNumber: Int, paragraph: String) {
        self.firstVerseNumber = firstVerseNumber
        self.verses = ParagraphParser.parse(paragraph)
    }

    var body: some View {
        VerseText()
    }

    func VerseText() -> Text {
        return verses.reduce(Text(""), { acc, verse in
            var verseText = acc

            // Append verse number if available
            if let number = verse.number {
                verseText = verseText
                    + Text(" \(number) ")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .baselineOffset(6.0)
            }

            // Append verse segments
            for segment in verse.segments {
                switch segment {
                case .regular(let text):
                    verseText = verseText
                        + Text(text)
                            .font(Font.custom(fontName, size: CGFloat(fontSize)))
                case .jesus(let text):
                    verseText = verseText
                        + Text(text)
                            .font(Font.custom(fontName, size: CGFloat(fontSize)))
                            .foregroundColor(showJesusWordsInRed ? .red : .primary)
                }
            }

            return verseText
        })
    }
}


#Preview {
    ParagraphView(
        firstVerseNumber: 13,
        paragraph: "And when he went out the second day, behold, two men of the Hebrews strove together: and he said to him that did the wrong, Wherefore smitest thou thy fellow? 2:14 And he said, Who made thee a prince and a judge over us? intendest thou to kill me, as thou killedst the Egyptian? And Moses feared, and said, Surely this thing is known."
    )
}
