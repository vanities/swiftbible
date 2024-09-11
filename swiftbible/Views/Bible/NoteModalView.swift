//
//  NoteModalView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/11/24.
//

import SwiftUI


struct NoteModalView: View {
    @Environment(\.modelContext) private var context
    @State var note: Note
    var onSave: (Note) -> Void
    var onCancel: () -> Void
    var onDelete: (Note) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(note.version.capitalized)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Book")
                        Spacer()
                        Text(note.book)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Verse")
                        Spacer()
                        Text("Chapter \(note.chapter):\(note.startingVerse)")
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Note")) {
                    TextEditor(text: $note.text)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Save") {
                        onSave(note)
                    }
                    Button("Cancel") {
                        onCancel()
                    }
                    Button("Delete") {
                        onDelete(note)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Edit Note", displayMode: .inline)
            .navigationBarItems(trailing: EmptyView())
        }
    }
}
