//
//  SeeSavedNotesView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import SwiftUI
import SwiftData


struct SeeSavedNotesView: View {
    @Environment(AppViewModel.self) private var appViewModel
    
    @Query private var notes: [Note] = []

    @Binding var selectedTab: Int

    var body: some View {
        VStack {
            if notes.isEmpty {
                Text("No Notes saved")
                
            } else {
                List {
                    ForEach(notes) { note in
                        Button(action: {
                            guard let bibleData = appViewModel.allBibleData,
                                  let book = bibleData.first(where: { $0.name == note.book }),
                                  let chapter = book.chapters.first(where: { $0.number == note.chapter })
                            else { return }
                            selectedTab = 0
                            appViewModel.selectedVerse = SelectedVerse(
                                book: book,
                                chapter: chapter,
                                verse: note.startingVerse
                            )
                            appViewModel.showSelectedVerse = true
                        }) {
                            VStack(alignment: .leading) {
                                Text(note.text)
                                    .font(.headline)
                                
                                
                                Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
                                    .font(.headline)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                Text("Created: \(note.created.formatted(date: .long, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Saved Notes")
    }
}

#Preview {
    SeeSavedNotesView(selectedTab: .constant(2))
        .environment(UserViewModel())
}
