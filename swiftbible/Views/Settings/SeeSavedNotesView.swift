//
//  SeeSavedNotesView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import SwiftData

struct SeeSavedNotesView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Query private var notes: [Note] = []

    @Binding var selectedTab: Tabs

    @State private var searchText = ""
    @State private var sortOrder: ListSortOrder = .newest
    @State private var versionFilter: String = ""

    private var availableVersions: [String] {
        Array(Set(notes.map { $0.version })).sorted()
    }

    private var displayedNotes: [Note] {
        let versionFiltered = versionFilter.isEmpty
            ? notes
            : notes.filter { $0.version == versionFilter }
        let searched: [Note] = searchText.isEmpty ? versionFiltered : versionFiltered.filter { note in
            note.text.localizedCaseInsensitiveContains(searchText)
                || note.book.localizedCaseInsensitiveContains(searchText)
                || note.version.localizedCaseInsensitiveContains(searchText)
        }
        return searched.sorted { lhs, rhs in
            sortOrder == .newest ? lhs.created > rhs.created : lhs.created < rhs.created
        }
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .symbolEffect(.wiggle, options: .repeating)
                    Text("No saved notes yet")
                        .font(.headline)
                    Text("Long-press any verse, then tap Note to write your reflection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if displayedNotes.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(displayedNotes) { note in
                            Button(action: {
                                selectedTab = .bible
                                appViewModel.navigateToVerse(
                                    bookName: note.book,
                                    chapterNumber: note.chapter,
                                    verseNumber: note.startingVerse,
                                    version: Version(rawValue: note.version)
                                )
                            }) {
                                VStack(alignment: .leading) {
                                    Text(note.text)

                                    Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
                                        .foregroundColor(.gray)

                                    Text("Created: \(note.created.formatted(date: .long, time: .omitted))")
                                        .foregroundColor(.gray)
                                }
                                .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search notes")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortAndFilterMenu
                    }
                }
            }
        }
        .navigationBarTitle("Saved Notes")
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
    SeeSavedNotesView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
