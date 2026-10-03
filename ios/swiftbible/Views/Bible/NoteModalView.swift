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
        NavigationStack {
            Form {
                Section(header: Text("Note Details")) {
                    Text("\(note.version.uppercased()) \(note.book) \(note.chapter):\(note.startingVerse)")
                        .foregroundColor(themedTextColor)
                }

                Section(header: Text("Note")) {
                    TextEditor(text: $note.text)
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(themedTextColor)
                        .accessibilityIdentifier("NoteEditorText")
                }
                .listRowBackground(readingTheme.isCustom ? editorFill : nil)

                Section {
                    Button("Delete", role: .destructive) {
                        onDelete(note)
                    }
                    .accessibilityHint("Permanently delete this note")
                }
            }
            .readingThemeContentBackground(readingTheme, colorScheme: colorScheme)
            .readingThemeBackground(readingTheme, colorScheme: colorScheme)
            .font(Font.custom(fontName, size: CGFloat(fontSize), relativeTo: .body))
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(note) }
                        .accessibilityHint("Save this note")
                }
            }
        }
    }
}
