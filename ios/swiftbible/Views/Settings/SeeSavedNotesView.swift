//
//  SeeSavedNotesView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI
import SwiftData

enum NoteSort: String, CaseIterable, Identifiable {
    case recent = "Recent first"
    case oldest = "Oldest first"
    case book = "Book order"
    var id: String { rawValue }
}

struct SeeSavedNotesView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Query private var notes: [Note] = []

    @Binding var selectedTab: Tabs

    @State private var query: String = ""
    @State private var sort: NoteSort = .recent
    @State private var bookFilter: String?

    private var bookOptions: [String] {
        Array(Set(notes.map { $0.book })).sorted()
    }

    private var filtered: [Note] {
        var items = notes
        if let bookFilter {
            items = items.filter { $0.book == bookFilter }
        }
        if !query.isEmpty {
            let q = query.lowercased()
            items = items.filter {
                $0.text.lowercased().contains(q) ||
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
                VStack(spacing: 0) {
                    if bookOptions.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterPill(label: "All", isSelected: bookFilter == nil) { bookFilter = nil }
                                ForEach(bookOptions, id: \.self) { book in
                                    FilterPill(label: book, isSelected: bookFilter == book) {
                                        bookFilter = (bookFilter == book) ? nil : book
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }
                    List {
                        ForEach(filtered) { note in
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
                    .listStyle(.insetGrouped)
                }
            }
        }
        .searchable(text: $query, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(NoteSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .navigationBarTitle("Saved Notes")
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        isSelected ? Color.accentColor.opacity(0.18) : Color(uiColor: .secondarySystemBackground)
                    )
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1.5
                    )
                )
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SeeSavedNotesView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
