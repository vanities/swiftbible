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
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }
    private var themedTextColor: Color {
        readingTheme.isCustom ? readingTheme.textColor(for: colorScheme) : .primary
    }
    private var editorFill: Color {
        readingTheme.isCustom
            ? readingTheme.secondaryTextColor(for: colorScheme).opacity(0.12)
            : Color(.secondarySystemGroupedBackground)
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Note Details")) {
                        Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
                            .foregroundColor(themedTextColor)
                    }

                    Section(header: Text("Note")) {
                        TextEditor(text: $note.text)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(themedTextColor)
                    }
                    .listRowBackground(readingTheme.isCustom ? editorFill : nil)
                }
                .readingThemeContentBackground(readingTheme, colorScheme: colorScheme)
                Section {
                    Button("Save") {
                        onSave(note)
                    }
                    .bold()
                    .padding()
                    .accessibilityHint("Save this note")
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
                    .accessibilityHint("Permanently delete this note")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .readingThemeBackground(readingTheme, colorScheme: colorScheme)
            .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
            .navigationBarTitle("Edit Note", displayMode: .inline)
            .navigationBarItems(trailing: EmptyView())
        }
    }
}
