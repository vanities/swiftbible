//
//  SeeHighlightsView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import SwiftData

struct SeeHighlightsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Query private var highlightedVerses: [HighlightedVerse] = []

    @Binding var selectedTab: Tabs

    @State private var searchText = ""
    @State private var sortOrder: ListSortOrder = .newest
    @State private var versionFilter: String = ""

    private var availableVersions: [String] {
        Array(Set(highlightedVerses.map { $0.version })).sorted()
    }

    private var displayedHighlights: [HighlightedVerse] {
        let versionFiltered = versionFilter.isEmpty
            ? highlightedVerses
            : highlightedVerses.filter { $0.version == versionFilter }
        let searched: [HighlightedVerse] = searchText.isEmpty ? versionFiltered : versionFiltered.filter { verse in
            verse.book.localizedCaseInsensitiveContains(searchText)
                || verse.version.localizedCaseInsensitiveContains(searchText)
        }
        return searched.sorted { lhs, rhs in
            sortOrder == .newest ? lhs.created > rhs.created : lhs.created < rhs.created
        }
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
                List {
                    if displayedHighlights.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(displayedHighlights) { highlightedVerse in
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
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search highlights")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortAndFilterMenu
                    }
                }
            }
        }
        .navigationBarTitle("Highlighted Verses")
    }

    private var sortAndFilterMenu: some View {
        Menu {
            Picker("Sort", selection: $sortOrder) {
                ForEach(ListSortOrder.allCases) { order in
                    Label(order.label, systemImage: order.systemImage).tag(order)
                }
            }
            if availableVersions.count > 1 {
                Picker("Version", selection: $versionFilter) {
                    Text("All Versions").tag("")
                    ForEach(availableVersions, id: \.self) { version in
                        Text(version.uppercased()).tag(version)
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Sort and filter")
    }
}

#Preview {
    SeeHighlightsView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
