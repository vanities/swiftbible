//
//  ContentView.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI
import StoreKit

struct BibleView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.requestReview) var requestReview

    @State private var bibleData: (oldTestament: [Book], newTestament: [Book], apocrypha: [Book], enoch: [Book]) = ([], [], [], [])
    @State private var searchText = ""
    @AppStorage("showApocrypha") var showApocrypha = false

    var filteredOldTestament: [Book] {
        if searchText.isEmpty {
            return bibleData.oldTestament
        } else {
            return bibleData.oldTestament.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredNewTestament: [Book] {
        if searchText.isEmpty {
            return bibleData.newTestament
        } else {
            return bibleData.newTestament.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredApocrypha: [Book] {
        if searchText.isEmpty {
            return bibleData.apocrypha
        } else {
            return bibleData.apocrypha.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredEnoch: [Book] {
        if searchText.isEmpty {
            return bibleData.enoch
        } else {
            return bibleData.enoch.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        @Bindable var appViewModel = appViewModel

        NavigationStack {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)

                // Bible Books List
                List {
                    // Old Testament Section with grouped headers
                    Section(header: Text("Old Testament")) {
                        // Torah (Instruction)
                        let torah = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"]
                        let former = ["Joshua", "Judges", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings"]
                        let latter = ["Isaiah", "Jeremiah", "Ezekiel"]
                        let minor = ["Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi"]
                        let poetic = ["Psalms", "Proverbs", "Job"]
                        let megillot = ["Song of Solomon", "Ruth", "Lamentations", "Ecclesiastes", "Esther"]
                        let historical = ["Daniel", "Ezra", "Nehemiah", "1 Chronicles", "2 Chronicles"]

                        groupSection("Torah (Instruction)", books: torah, within: filteredOldTestament)

                        groupSection("Nevi'im (Prophets) — Former", books: former, within: filteredOldTestament)
                        groupSection("Nevi'im (Prophets) — Latter", books: latter, within: filteredOldTestament)
                        groupSection("Nevi'im (Prophets) — Minor", books: minor, within: filteredOldTestament)

                        groupSection("Ketuvim (Writings) — Poetic", books: poetic, within: filteredOldTestament)
                        groupSection("Ketuvim (Writings) — Five Megillot", books: megillot, within: filteredOldTestament)
                        groupSection("Ketuvim (Writings) — Historical", books: historical, within: filteredOldTestament)
                    }

                    // New Testament Section with grouped headers
                    Section(header: Text("New Testament")) {
                        let gospels = ["Matthew", "Mark", "Luke", "John"]
                        let history = ["Acts"]
                        let pauline = [
                            "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians",
                            "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon"
                        ]
                        let general = ["Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude"]
                        let apocalypse = ["Revelation"]

                        groupSection("Gospels", books: gospels, within: filteredNewTestament)
                        groupSection("History", books: history, within: filteredNewTestament)
                        groupSection("Pauline Epistles", books: pauline, within: filteredNewTestament)
                        groupSection("General Epistles", books: general, within: filteredNewTestament)
                        groupSection("Apocalypse", books: apocalypse, within: filteredNewTestament)
                    }

                    // Apocrypha Section (Conditional)
                    if showApocrypha && !filteredApocrypha.isEmpty {
                        Section(header: Text("Apocrypha")) {
                            let deuterocanonical = [
                                "Tobit", "Judith", "Additions to Esther", "1 Maccabees", "2 Maccabees",
                                "Wisdom of Solomon", "Ecclesiasticus", "Baruch", "Letter of Jeremiah",
                                // Daniel additions often split into these entries
                                "Prayer of Azariah", "Susanna", "Bel and the Dragon"
                            ]
                            let orthodoxOnly = [
                                "1 Esdras", "2 Esdras", "Prayer of Manasseh", "Psalm 151", "3 Maccabees", "4 Maccabees"
                            ]

                            groupSection("Deuterocanonical", books: deuterocanonical, within: filteredApocrypha)
                            groupSection("Orthodox only", books: orthodoxOnly, within: filteredApocrypha)
                        }
                    }

                    // Book of Enoch Section (Conditional - same as Apocrypha)
                    if showApocrypha && !filteredEnoch.isEmpty {
                        Section(header: Text("Book of Enoch")) {
                            ForEach(filteredEnoch, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
        }
        .onAppear {
            fetchBibleData()
            fetchApocryphaData()
            fetchEnochData()
            #if !DEBUG
            requestReview()
            #endif
        }
            .onChange(of: showApocrypha) { _, newValue in
                if newValue && bibleData.apocrypha.isEmpty {
                    fetchApocryphaData()
                }
                if newValue && bibleData.enoch.isEmpty {
                    fetchEnochData()
                }
                // Optionally, clear data when hidden
                // if !newValue {
                //     bibleData.apocrypha = []
                //     bibleData.enoch = []
                // }
            }
            .navigationTitle("Bible")
            .navigationDestination(isPresented: $appViewModel.showSelectedVerse) {
                if let book = appViewModel.selectedVerse?.book,
                   let chapter = appViewModel.selectedVerse?.chapter {
                    ChapterDetailView(
                        book: book,
                        chapter: chapter
                    )
                }
            }
            .ignoresSafeArea(.all, edges: .horizontal)
            .accessibilityIdentifier("BibleView")
        }
    }

    // MARK: - Helpers for grouped sections
    private func booksInOrder(names: [String], available: [Book]) -> [Book] {
        names.compactMap { name in available.first { $0.name == name } }
    }

    @ViewBuilder
    private func groupHeader(_ title: String) -> some View {
        // Show header only if any following items for that group are present will render;
        // The header itself is lightweight, so we always display; empty groups will have no rows.
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func groupedBooks(_ names: [String], within available: [Book]) -> some View {
        let items = booksInOrder(names: names, available: available)
        if !items.isEmpty {
            ForEach(items, id: \.name) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    NavigationTitle(name: book.name, description: book.description)
                }
            }
        }
    }

    @ViewBuilder
    private func groupSection(_ title: String, books names: [String], within available: [Book]) -> some View {
        let items = booksInOrder(names: names, available: available)
        if !items.isEmpty {
            groupHeader(title)
            ForEach(items, id: \.name) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    NavigationTitle(name: book.name, description: book.description)
                }
            }
        }
    }

    // Fetch Bible Data (Old and New Testament)
    private func fetchBibleData() {
        let fetchedData = BibleService.shared.fetchBibleData()
        bibleData.oldTestament = fetchedData.oldTestament
        bibleData.newTestament = fetchedData.newTestament
        appViewModel.allBibleData = bibleData.oldTestament + bibleData.newTestament
    }

    // Fetch Apocrypha Data
    private func fetchApocryphaData() {
        let fetchedApocrypha = BibleService.shared.fetchApocryphaData()
        bibleData.apocrypha = fetchedApocrypha
        if let allBibleData = appViewModel.allBibleData {
            if allBibleData.isEmpty {
                appViewModel.allBibleData = fetchedApocrypha
            } else {
                appViewModel.allBibleData?.append(contentsOf: fetchedApocrypha)
            }
        } else {
            appViewModel.allBibleData = fetchedApocrypha
        }
    }

    // Fetch Enoch Data
    private func fetchEnochData() {
        let fetchedEnoch = BibleService.shared.fetchEnochData()
        bibleData.enoch = fetchedEnoch
        if let allBibleData = appViewModel.allBibleData {
            if allBibleData.isEmpty {
                appViewModel.allBibleData = fetchedEnoch
            } else {
                appViewModel.allBibleData?.append(contentsOf: fetchedEnoch)
            }
        } else {
            appViewModel.allBibleData = fetchedEnoch
        }
    }
}

#if DEBUG
struct BibleView_Previews: PreviewProvider {
    static var previews: some View {
        BibleView()
            .environment(UserViewModel())
            .environment(AppViewModel())
    }
}
#endif
