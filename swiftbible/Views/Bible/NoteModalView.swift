//
//  NoteModalView.swift
//  swiftbible
//
//  Created on 9/11/24.
//

import SwiftUI


struct NoteModalView: View {
    @Environment(\.modelContext) private var context
    @State var note: Note
    var onSave: (Note) -> Void
    var onCancel: () -> Void
    var onDelete: (Note) -> Void

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Note Details")) {
                        Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
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
            .font(Font.custom(fontName, size: CGFloat(fontSize)))
            .navigationBarTitle("Edit Note", displayMode: .inline)
            .navigationBarItems(trailing: EmptyView())
        }
    }
}
