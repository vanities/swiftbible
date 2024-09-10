//
//  VerseView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/6/24.
//

import SwiftUI


struct ParagraphView: View {
    @AppStorage("fontSize") private var fontSize: Int = 20
    let firstVerseNumber: Int
    let verses: [Verse]


    init(firstVerseNumber: Int,
         paragraph: String) {
        self.firstVerseNumber = firstVerseNumber
        self.verses = ParagraphParser.parse(paragraph)
    }

    var body: some View {
        VerseText()
    }

    func VerseText() -> Text {
        return verses.reduce(
            Text(""),
            {
                $0
                + Text("\($1.number != nil ? " \($1.number!) " : "")")
                    .foregroundStyle(.gray)
                    .font(.footnote)
                    .baselineOffset(6.0)
                + Text("\($1.text)")
                    .font(Font.system(size: CGFloat(fontSize)))
            }
        )
    }

}

#Preview {
    ParagraphView(
        firstVerseNumber: 13,
        paragraph: "And when he went out the second day, behold, two men of the Hebrews strove together: and he said to him that did the wrong, Wherefore smitest thou thy fellow? 2:14 And he said, Who made thee a prince and a judge over us? intendest thou to kill me, as thou killedst the Egyptian? And Moses feared, and said, Surely this thing is known."
    )
}
