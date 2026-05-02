//
//  HistoryView.swift
//  swiftbible
//
//  Top-level History screen — pushed from Settings (More tab).
//  Inherits the enclosing NavigationStack so nav nests cleanly.
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                masthead

                if let featured = HistoryContent.allSections.first {
                    NavigationLink(destination: HistorySectionView(section: featured)) {
                        HistorySectionCard(section: featured, isFeatured: true)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(Array(HistoryContent.allSections.dropFirst()), id: \.id) { section in
                    NavigationLink(destination: HistorySectionView(section: section)) {
                        HistorySectionCard(section: section, isFeatured: false)
                    }
                    .buttonStyle(.plain)
                }

                footer
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.hidden)
        .parchmentBackground()
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var masthead: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Rectangle().frame(width: 30, height: 1).foregroundStyle(ManuscriptPalette.accent)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(ManuscriptPalette.accent)
                Rectangle().frame(width: 30, height: 1).foregroundStyle(ManuscriptPalette.accent)
            }
            Text("A BRIEF HISTORY OF")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .tracking(4)
                .foregroundStyle(ManuscriptPalette.accent)
            Text("the Christian Church")
                .font(.system(size: 30, weight: .black, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
            Text("From the patriarchs to today — Israel, the canon,\nthe councils, the splits, and the practices of worship.")
                .font(.system(size: 13, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .foregroundStyle(ManuscriptPalette.mutedInk(.light))
                .padding(.top, 2)
        }
        .padding(.top, 4)
        .padding(.bottom, 18)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Rectangle().frame(width: 24, height: 1).foregroundStyle(ManuscriptPalette.accent.opacity(0.5))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(ManuscriptPalette.accent.opacity(0.7))
                Rectangle().frame(width: 24, height: 1).foregroundStyle(ManuscriptPalette.accent.opacity(0.5))
            }
            Text("Written from a neutral, descriptive perspective.\nEvery claim links to primary or scholarly sources.")
                .font(.system(size: 11, design: .serif))
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .foregroundStyle(ManuscriptPalette.mutedInk(.light).opacity(0.8))
        }
        .padding(.top, 16)
    }
}
