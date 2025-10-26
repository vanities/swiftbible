//
//  SavedDevotionalsListView.swift
//  swiftbible
//
//  Created on 2/15/25.
//

import SwiftUI
import SwiftData

struct SavedDevotionalsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavedDevotional.date, order: .reverse) private var savedDevotionals: [SavedDevotional]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    var body: some View {
        List {
            if savedDevotionals.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "heart")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No saved devotionals yet")
                        .font(.headline)
                    Text("Tap the heart on any devotional to save it for later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
            } else {
                ForEach(savedDevotionals) { devotional in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateFormatter.string(from: devotional.date))
                            .font(.headline)
                        Text(devotional.message)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 8)
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
        }
        .navigationTitle("Saved Devotionals")
        .listStyle(.insetGrouped)
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

#Preview {
    SavedDevotionalsListView()
        .modelContainer(for: SavedDevotional.self, inMemory: true)
}
