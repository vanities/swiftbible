//
//  SeeHighlightsView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import SwiftData

enum HighlightSort: String, CaseIterable, Identifiable {
    case recent = "Recent first"
    case oldest = "Oldest first"
    case book = "Book order"
    var id: String { rawValue }
}

struct SeeHighlightsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Query private var highlightedVerses: [HighlightedVerse] = []

    @Binding var selectedTab: Tabs

    @State private var query: String = ""
    @State private var sort: HighlightSort = .recent
    @State private var colorFilter: String?

    private var palette: [String] {
        Array(Set(highlightedVerses.map { $0.color })).sorted()
    }

    private var filtered: [HighlightedVerse] {
        var items = highlightedVerses
        if let colorFilter {
            items = items.filter { $0.color == colorFilter }
        }
        if !query.isEmpty {
            let q = query.lowercased()
            items = items.filter {
                "\($0.book) \($0.chapter):\($0.startingVerse)".lowercased().contains(q)
            }
        }
        switch sort {
        case .recent: items.sort { $0.created > $1.created }
        case .oldest: items.sort { $0.created < $1.created }
        case .book: items.sort {
            if $0.book != $1.book { return $0.book < $1.book }
            if $0.chapter != $1.chapter { return $0.chapter < $1.chapter }
            return $0.startingVerse < $1.startingVerse
        }
        }
        return items
    }

    var body: some View {
        Group {
            if highlightedVerses.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "highlighter")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text("No highlighted verses yet")
                        .font(.headline)
                    Text("Long-press any verse, then tap Highlight to mark it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    if palette.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ColorChip(label: "All", isSelected: colorFilter == nil, fill: nil) { colorFilter = nil }
                                ForEach(palette, id: \.self) { hex in
                                    ColorChip(label: nil, isSelected: colorFilter == hex, fill: Color(hex: hex)) {
                                        colorFilter = (colorFilter == hex) ? nil : hex
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                    List {
                        ForEach(filtered) { highlightedVerse in
                            Button(action: {
                                selectedTab = .bible
                                appViewModel.navigateToVerse(
                                    bookName: highlightedVerse.book,
                                    chapterNumber: highlightedVerse.chapter,
                                    verseNumber: highlightedVerse.startingVerse,
                                    version: Version(rawValue: highlightedVerse.version)
                                )
                            }) {
                                VStack(alignment: .leading) {
                                    Text("\(highlightedVerse.version.uppercased()) \(highlightedVerse.book) \(highlightedVerse.chapter):\(highlightedVerse.startingVerse)")
                                    Text("Created: \(highlightedVerse.created.formatted(date: .long, time: .omitted))")
                                        .foregroundColor(.gray)
                                }
                                .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .searchable(text: $query, prompt: "Search highlights")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(HighlightSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .navigationBarTitle("Highlighted Verses")
    }
}

private struct ColorChip: View {
    let label: String?
    let isSelected: Bool
    let fill: Color?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let label {
                    Capsule().fill(Color(uiColor: .secondarySystemBackground))
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                } else {
                    Circle().fill(fill ?? .gray)
                }
            }
            .frame(width: label == nil ? 32 : nil, height: 32)
            .overlay(
                Group {
                    if isSelected {
                        if label != nil { Capsule().stroke(Color.accentColor, lineWidth: 2) } else { Circle().stroke(Color.accentColor, lineWidth: 2) }
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SeeHighlightsView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
