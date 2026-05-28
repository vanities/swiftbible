//
//  HistorySectionView.swift
//  swiftbible
//
//  Middle level — list of articles in a section.
//

import SwiftUI

struct HistorySectionView: View {
    let section: HistorySection
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header

                ForEach(Array(section.articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink(destination: HistoryArticleView(article: article)) {
                        HistoryArticleRow(article: article, index: index + 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .parchmentBackground()
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(systemName: section.symbol)
                .font(.system(size: 30))
                .foregroundStyle(ManuscriptPalette.accent)
                .padding(.top, 8)

            EraBadge(era: section.era)

            Text(section.title)
                .font(.system(size: 26, weight: .black, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))

            Text(section.subtitle)
                .font(.system(size: 14, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                .padding(.horizontal, 16)

            HStack(spacing: 10) {
                Rectangle().frame(width: 30, height: 1).foregroundStyle(ManuscriptPalette.accent)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(ManuscriptPalette.accent)
                Rectangle().frame(width: 30, height: 1).foregroundStyle(ManuscriptPalette.accent)
            }
            .padding(.bottom, 6)
        }
        .padding(.bottom, 8)
    }
}
