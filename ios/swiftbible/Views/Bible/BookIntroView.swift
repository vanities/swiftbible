//
//  BookIntroView.swift
//  swiftbible
//
//  The "About this book" screen reached from the first row of the chapter
//  list. Shows the longer-form introduction (authorship, date, historical
//  setting, and purpose) for a book, drawn from the user's selected summary
//  source with a fallback chain, and attributes whichever source supplied it.
//

import SwiftUI

struct BookIntroView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    let bookName: String
    let resolved: ResolvedBookIntro

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

    private var textColor: Color {
        readingTheme.isCustom ? readingTheme.textColor(for: colorScheme) : .primary
    }

    private var secondaryColor: Color {
        readingTheme.isCustom ? readingTheme.secondaryTextColor(for: colorScheme) : .secondary
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(resolved.intro.title)
                    .font(Font.custom(fontName, size: CGFloat(fontSize) + 6, relativeTo: .title2))
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
                    .accessibilityAddTraits(.isHeader)

                ForEach(Array(resolved.intro.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                attribution
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .readingThemeScreen(readingTheme, colorScheme: colorScheme)
        .navigationTitle("About \(bookName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsService.shared.capture(.bookIntroViewed, properties: [
                "book": bookName,
                "source": resolved.attribution.shortName
            ])
        }
    }

    private var attribution: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.bottom, 4)
            Text(resolved.attribution.name)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(secondaryColor)
            Text("\(resolved.attribution.attribution) · \(resolved.attribution.license)")
                .font(.caption)
                .foregroundStyle(secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
