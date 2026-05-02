//
//  HistoryArticleView.swift
//  swiftbible
//
//  Leaf article reader. Renders body blocks, pull quotes, sources,
//  and links to related articles.
//

import SwiftUI

struct HistoryArticleView: View {
    let article: HistoryArticle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                articleHeader

                ForEach(Array(article.body.enumerated()), id: \.offset) { index, block in
                    BodyBlockView(block: block, isOpening: index == 0)
                }

                if !article.pullQuotes.isEmpty {
                    VStack(spacing: 18) {
                        ForEach(article.pullQuotes) { quote in
                            PullQuoteView(quote: quote)
                        }
                    }
                    .padding(.top, 10)
                }

                if !article.sources.isEmpty {
                    sourcesSection
                }

                if !article.related.isEmpty {
                    relatedSection
                }

                colophon
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
        .parchmentBackground()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleHeader: some View {
        VStack(alignment: .center, spacing: 12) {
            EraBadge(era: article.era)
                .padding(.top, 4)

            Text(article.title)
                .font(.system(size: 30, weight: .black, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                .lineSpacing(2)

            Text(article.subtitle)
                .font(.system(size: 16, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                .padding(.horizontal, 8)

            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("\(article.estimatedMinutes) min read")
                    .font(.system(size: 12, design: .serif))
                    .italic()
            }
            .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))

            HStack(spacing: 10) {
                Rectangle().frame(width: 40, height: 1).foregroundStyle(ManuscriptPalette.accent)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(ManuscriptPalette.accent)
                Rectangle().frame(width: 40, height: 1).foregroundStyle(ManuscriptPalette.accent)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Sources")
            VStack(spacing: 8) {
                ForEach(article.sources) { source in
                    SourceLinkView(source: source)
                }
            }
        }
        .padding(.top, 18)
    }

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Related")
            VStack(spacing: 8) {
                ForEach(article.related, id: \.self) { id in
                    if let related = HistoryContent.article(id: id) {
                        NavigationLink(destination: HistoryArticleView(article: related)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(related.title)
                                        .font(.system(size: 15, weight: .semibold, design: .serif))
                                        .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                                        .multilineTextAlignment(.leading)
                                    Text(related.subtitle)
                                        .font(.system(size: 12, design: .serif))
                                        .italic()
                                        .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ManuscriptPalette.accent)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(ManuscriptPalette.cardSurface(colorScheme))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .strokeBorder(ManuscriptPalette.cardBorder(colorScheme), lineWidth: 0.5)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 8) {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(3)
                .foregroundStyle(ManuscriptPalette.accent)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.4))
        }
    }

    private var colophon: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Rectangle().frame(width: 20, height: 1).foregroundStyle(ManuscriptPalette.accent.opacity(0.5))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(ManuscriptPalette.accent.opacity(0.7))
                Rectangle().frame(width: 20, height: 1).foregroundStyle(ManuscriptPalette.accent.opacity(0.5))
            }
            Text("Fin.")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
    }
}
