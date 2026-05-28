//
//  SavedDevotionalsListView.swift
//  swiftbible
//
//  Created on 2/15/25.
//

import SwiftUI
import SwiftData
import MarkdownUI

enum SavedDevoSort: String, CaseIterable, Identifiable {
    case recent = "Recent first"
    case oldest = "Oldest first"
    var id: String { rawValue }
}

struct SavedDevotionalsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedDevotional.date, order: .reverse) private var savedDevotionals: [SavedDevotional]

    @State private var query: String = ""
    @State private var sort: SavedDevoSort = .recent

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    private var filtered: [SavedDevotional] {
        var items = savedDevotionals
        if !query.isEmpty {
            let q = query.lowercased()
            items = items.filter {
                $0.message.lowercased().contains(q) ||
                dateFormatter.string(from: $0.date).lowercased().contains(q)
            }
        }
        switch sort {
        case .recent: items.sort { $0.date > $1.date }
        case .oldest: items.sort { $0.date < $1.date }
        }
        return items
    }

    var body: some View {
        Group {
            if savedDevotionals.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "heart")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse, options: .repeating)
                    Text("No saved devotionals yet")
                        .font(.headline)
                    Text("Tap the heart on any devotional to save it for later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filtered) { devotional in
                        NavigationLink {
                            SavedDevotionalDetailView(devotional: devotional)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(dateFormatter.string(from: devotional.date))
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(devotional.message.preview(maxLength: 150))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityHint("Double tap to read. Long press for options.")
                        .contextMenu {
                            Button(role: .destructive) {
                                delete(devotional)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $query, prompt: "Search devotionals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(SavedDevoSort.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
        .navigationTitle("Saved Devotionals")
    }

    private func delete(_ devotional: SavedDevotional) {
        context.delete(devotional)
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let devotional = savedDevotionals[index]
            delete(devotional)
        }
    }
}

struct SavedDevotionalDetailView: View {
    let devotional: SavedDevotional
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(dateFormatter.string(from: devotional.date))
                    .font(.title2)
                    .fontWeight(.bold)

                Markdown(devotional.message)
                    .markdownTextStyle(\.text) {
                        FontSize(17)
                    }
            }
            .padding()
        }
        .navigationTitle("Devotional")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
            }
        }
    }

    private func delete() {
        dismiss()
        context.delete(devotional)
        try? context.save()
    }
}

private extension String {
    func preview(maxLength: Int) -> String {
        // Remove markdown formatting for preview
        let cleanText = self
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanText.count <= maxLength {
            return cleanText
        }

        let truncated = cleanText.prefix(maxLength)
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return String(truncated) + "..."
    }
}

#Preview {
    NavigationStack {
        SavedDevotionalsListView()
            .modelContainer(for: SavedDevotional.self, inMemory: true)
    }
}
