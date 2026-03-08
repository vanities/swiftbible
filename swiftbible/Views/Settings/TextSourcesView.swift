//
//  TextSourcesView.swift
//  swiftbible
//

import SwiftUI

struct TextSourceInfo: Identifiable {
    let id = UUID()
    let name: String
    let translation: String
    let year: String
    let status: String
    let category: String
}

struct TextSourcesView: View {
    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    private let sources: [TextSourceInfo] = [
        // Bible translations
        TextSourceInfo(
            name: "King James Version (KJV)",
            translation: "47 scholars commissioned by King James I",
            year: "1611",
            status: "Public Domain",
            category: "Bible Translations"
        ),
        TextSourceInfo(
            name: "American Standard Version (ASV)",
            translation: "Philip Schaff and 30 American/British scholars",
            year: "1901",
            status: "Public Domain",
            category: "Bible Translations"
        ),
        TextSourceInfo(
            name: "World English Bible (WEB)",
            translation: "Michael Paul Johnson (updated from ASV)",
            year: "1994-2020",
            status: "Public Domain (dedicated)",
            category: "Bible Translations"
        ),
        // Deuterocanonical
        TextSourceInfo(
            name: "Apocrypha (Deuterocanonical Books)",
            translation: "King James Version translators",
            year: "1611",
            status: "Public Domain",
            category: "Deuterocanonical"
        ),
        // Jewish Pseudepigrapha
        TextSourceInfo(
            name: "1 Enoch (Book of Enoch)",
            translation: "R.H. Charles",
            year: "1917",
            status: "Public Domain",
            category: "Jewish Pseudepigrapha"
        ),
        TextSourceInfo(
            name: "2 Enoch (Secrets of Enoch)",
            translation: "W.R. Morfill and R.H. Charles",
            year: "1896",
            status: "Public Domain",
            category: "Jewish Pseudepigrapha"
        ),
        TextSourceInfo(
            name: "Book of Jubilees",
            translation: "R.H. Charles",
            year: "1902",
            status: "Public Domain",
            category: "Jewish Pseudepigrapha"
        ),
        TextSourceInfo(
            name: "Testaments of the Twelve Patriarchs",
            translation: "R.H. Charles",
            year: "1908",
            status: "Public Domain",
            category: "Jewish Pseudepigrapha"
        ),
        // Early Christian Writings
        TextSourceInfo(
            name: "Didache (Teaching of the Twelve Apostles)",
            translation: "M.B. Riddle (Ante-Nicene Fathers, Vol. 7)",
            year: "1886",
            status: "Public Domain",
            category: "Early Christian Writings"
        ),
        TextSourceInfo(
            name: "1 Clement (Epistle of Clement)",
            translation: "John Keith (Ante-Nicene Fathers, Vol. 1)",
            year: "1885",
            status: "Public Domain",
            category: "Early Christian Writings"
        )
    ]

    private var groupedSources: [(category: String, sources: [TextSourceInfo])] {
        let categories = ["Bible Translations", "Deuterocanonical", "Jewish Pseudepigrapha", "Early Christian Writings"]
        return categories.compactMap { category in
            let items = sources.filter { $0.category == category }
            return items.isEmpty ? nil : (category: category, sources: items)
        }
    }

    var body: some View {
        List {
            Section {
                Text("All texts included in SwiftBible use public domain translations. Every translation listed below is freely available without copyright restrictions.")
                    .font(Font.custom(fontName, size: CGFloat(fontSize - 4)))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("About Our Sources")
            }

            ForEach(groupedSources, id: \.category) { group in
                Section {
                    ForEach(group.sources) { source in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(source.name)
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 2)))
                                .fontWeight(.medium)

                            HStack(spacing: 12) {
                                Label(source.year, systemImage: "calendar")
                                Spacer()
                                Text(source.status)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundStyle(.green)
                                    .cornerRadius(6)
                            }
                            .font(Font.custom(fontName, size: CGFloat(fontSize - 6)))
                            .foregroundStyle(.secondary)

                            Text("Translated by \(source.translation)")
                                .font(Font.custom(fontName, size: CGFloat(fontSize - 5)))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(group.category)
                }
            }
        }
        .navigationBarTitle("Text Sources")
    }
}

#Preview {
    NavigationStack {
        TextSourcesView()
    }
}
