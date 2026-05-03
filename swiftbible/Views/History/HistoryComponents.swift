//
//  HistoryComponents.swift
//  swiftbible
//
//  Reusable manuscript-styled UI components for the History tab —
//  cards, era badge, pull quote, source link, body block renderer,
//  and a serif drop cap for opening paragraphs.
//

import SwiftUI

// MARK: - Era badge (small caps gold label)

struct EraBadge: View {
    let era: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .frame(width: 14, height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.8))
            Text(era.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .tracking(2.5)
                .foregroundStyle(ManuscriptPalette.accent)
            Rectangle()
                .frame(width: 14, height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.8))
        }
    }
}

// MARK: - Section card on the top-level grid

struct HistorySectionCard: View {
    let section: HistorySection
    let isFeatured: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                EraBadge(era: section.era)
                Spacer()
                Image(systemName: section.symbol)
                    .font(.system(size: isFeatured ? 22 : 18))
                    .foregroundStyle(ManuscriptPalette.accent.opacity(0.9))
            }

            Text(section.title)
                .font(.system(size: isFeatured ? 30 : 22, weight: .bold, design: .serif))
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(section.subtitle)
                .font(.system(size: isFeatured ? 16 : 14, design: .serif))
                .italic()
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .overlay(ManuscriptPalette.accent.opacity(0.35))
                .padding(.top, 4)

            HStack {
                Text("\(section.articles.count) ARTICLES")
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(2)
                    .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ManuscriptPalette.accent)
            }
        }
        .padding(isFeatured ? 24 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ManuscriptPalette.cardSurface(colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ManuscriptPalette.cardBorder(colorScheme), lineWidth: 1)
                }
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                        radius: isFeatured ? 12 : 6, x: 0, y: 3)
        }
    }
}

// MARK: - Article row inside a section

struct HistoryArticleRow: View {
    let article: HistoryArticle
    let index: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(String(format: "%02d", index))
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(ManuscriptPalette.accent)
                Rectangle()
                    .frame(width: 18, height: 1)
                    .foregroundStyle(ManuscriptPalette.accent.opacity(0.6))
                Text(article.era.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .tracking(2)
                    .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                Spacer()
                Label("\(article.estimatedMinutes) min", systemImage: "clock")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
            }

            Text(article.title)
                .font(.system(size: 21, weight: .bold, design: .serif))
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(article.subtitle)
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ManuscriptPalette.cardSurface(colorScheme))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(ManuscriptPalette.cardBorder(colorScheme), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Pull quote (large quotation block)

struct PullQuoteView: View {
    let quote: PullQuote
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\u{201C}")
                .font(.system(size: 64, weight: .bold, design: .serif))
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.55))
                .frame(height: 28, alignment: .top)
                .padding(.bottom, -14)

            Text(quote.text)
                .font(.system(size: 19, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Rectangle()
                    .frame(width: 24, height: 1)
                    .foregroundStyle(ManuscriptPalette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(quote.attribution.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(ManuscriptPalette.accent)
                    if let context = quote.context {
                        Text(context)
                            .font(.system(size: 12, design: .serif))
                            .italic()
                            .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                    }
                }
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.03)
                      : Color.brandGoldLight.opacity(0.30))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .frame(width: 3)
                        .foregroundStyle(ManuscriptPalette.accent)
                }
        }
    }
}

// MARK: - Source link (external reference)

struct SourceLinkView: View {
    let source: HistorySource
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let urlString = source.url, let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                kindBadge

                VStack(alignment: .leading, spacing: 4) {
                    Text(source.title)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let author = source.author {
                        Text(author)
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                    }

                    if let note = source.note {
                        Text(note)
                            .font(.system(size: 12, design: .serif))
                            .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                if source.url != nil {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ManuscriptPalette.accent)
                        .padding(.top, 3)
                }
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
        .disabled(source.url == nil)
    }

    private var kindBadge: some View {
        Text(source.kind.label.uppercased())
            .font(.system(size: 9, weight: .bold, design: .serif))
            .tracking(1.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(badgeColor(for: source.kind))
            )
    }

    private func badgeColor(for kind: SourceKind) -> Color {
        switch kind {
        case .primary: return Color.brandRedDark
        case .scholarly: return Color.brandCoverDark
        case .encyclopedia: return Color.brandAccent
        case .scripture: return Color.brandGold
        }
    }
}

// MARK: - Timeline entry list

struct TimelineList: View {
    let entries: [TimelineEntry]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(ManuscriptPalette.accent)
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(ManuscriptPalette.accent.opacity(0.35))
                                .frame(width: 1)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.year)
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .tracking(0.5)
                            .foregroundStyle(ManuscriptPalette.accent)
                        Text(entry.event)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 14)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Body block renderer

struct BodyBlockView: View {
    let block: BodyBlock
    let isOpening: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch block {
        case .paragraph(let text):
            paragraph(text)
        case .heading(let text):
            heading(text)
        case .quote(let text, let attribution):
            inlineQuote(text: text, attribution: attribution)
        case .list(let items):
            listView(items)
        case .timeline(let entries):
            TimelineList(entries: entries)
        case .divider:
            ornamentDivider
        }
    }

    private func paragraph(_ text: String) -> some View {
        Group {
            if isOpening {
                openingParagraph(text)
            } else {
                Text(text)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func openingParagraph(_ text: String) -> some View {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if let first = trimmed.first {
            let rest = String(trimmed.dropFirst())
            HStack(alignment: .top, spacing: 6) {
                Text(String(first))
                    .font(.system(size: 60, weight: .black, design: .serif))
                    .foregroundStyle(ManuscriptPalette.accent)
                    .frame(width: 50, height: 56, alignment: .topLeading)
                    .padding(.top, -6)
                Text(rest)
                    .font(.system(size: 17, design: .serif))
                    .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Text(text)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
        }
    }

    private func heading(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text.uppercased())
                .font(.system(size: 12, weight: .bold, design: .serif))
                .tracking(2.5)
                .foregroundStyle(ManuscriptPalette.accent)
            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.6))
        }
        .padding(.top, 8)
    }

    private func inlineQuote(text: String, attribution: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\u{201C}\(text)\u{201D}")
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(attribution)")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(ManuscriptPalette.mutedInk(colorScheme))
        }
        .padding(.leading, 14)
        .overlay(alignment: .leading) {
            Rectangle()
                .frame(width: 2)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.6))
        }
    }

    private func listView(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\u{2022}")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundStyle(ManuscriptPalette.accent)
                        .frame(width: 12, alignment: .leading)
                    Text(item)
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(ManuscriptPalette.ink(colorScheme))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var ornamentDivider: some View {
        HStack {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.4))
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.7))
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(ManuscriptPalette.accent.opacity(0.4))
        }
        .padding(.vertical, 8)
    }
}
