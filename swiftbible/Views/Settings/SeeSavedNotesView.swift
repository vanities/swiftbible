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

    @Binding var selectedTab: Tabs

    var body: some View {
        VStack {
            if notes.isEmpty {
                Text("No Notes saved")
                
            } else {
                List {
                    ForEach(notes) { note in
                        Button(action: {
                            selectedTab = .bible
                            appViewModel.navigateToVerse(
                                bookName: note.book,
                                chapterNumber: note.chapter,
                                verseNumber: note.startingVerse
                            )
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
    SeeSavedNotesView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}
