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
            VStack {
                Form {
                    Section(header: Text("Note Details")) {
                        Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
                            .font(.headline)
                    }

                    Section(header: Text("Note")) {
                        TextEditor(text: $note.text)
                            .frame(minHeight: 100)
                    }

                }
                Section {
                    Button("Save") {
                        onSave(note)
                    }
                    .bold()
                    .padding()
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.gray)
                    .padding()
                    Button("Delete") {
                        onDelete(note)
                    }
                    .padding()
                    .foregroundColor(.red)
                }
            }
            .navigationBarTitle("Edit Note", displayMode: .inline)
            .navigationBarItems(trailing: EmptyView())
        }
    }
}
