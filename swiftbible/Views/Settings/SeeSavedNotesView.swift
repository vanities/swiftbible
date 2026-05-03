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
                    ForEach(notes) { note in
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
        .navigationBarTitle("Saved Notes")
    }
}

#Preview {
    SeeSavedNotesView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
