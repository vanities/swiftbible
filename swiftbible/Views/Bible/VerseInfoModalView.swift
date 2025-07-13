import SwiftUI
import MarkdownUI

struct VerseInfoModalView: View {
    let verseInfo: VerseInfo
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    var body: some View {
        NavigationView {
            ScrollView {
                Markdown(verseInfo.text)
                    .padding()
            }
            .navigationTitle("\(verseInfo.version.uppercased()) \(verseInfo.book) \(verseInfo.chapter):\(verseInfo.startingVerse)")
            .navigationBarTitleDisplayMode(.inline)
            .font(Font.custom(fontName, size: CGFloat(fontSize)))
        }
    }
}

#Preview {
    VerseInfoModalView(
        verseInfo: VerseInfo(
            version: "kjv",
            book: "Genesis",
            chapter: 1,
            startingVerse: 1,
            text: "Test verse info"
        )
    )
}
