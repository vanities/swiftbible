//
//  ContentView.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import SwiftUI

struct BibleView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(UserViewModel.self) private var userViewModel

    @State private var bibleData: (oldTestament: [Book], newTestament: [Book], apocrypha: [Book], enoch: [Book], jubilees: [Book], testaments: [Book], secondEnoch: [Book], didache: [Book], firstClement: [Book]) = ([], [], [], [], [], [], [], [], [])
    @State private var searchText = ""
    @AppStorage("showApocrypha") var showApocrypha = false
    @AppStorage("showJewishPseudepigraphaEnoch") var showJewishPseudepigraphaEnoch = false
    @AppStorage("showJubilees") var showJubilees = false
    @AppStorage("showTestaments") var showTestaments = false
    @AppStorage("showSecondEnoch") var showSecondEnoch = false
    @AppStorage("showDidache") var showDidache = false
    @AppStorage("showFirstClement") var showFirstClement = false
    @AppStorage("showThematicGrouping") var showThematicGrouping = false
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @Environment(\.colorScheme) private var colorScheme

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

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

    var filteredJubilees: [Book] {
        if searchText.isEmpty {
            return bibleData.jubilees
        } else {
            return bibleData.jubilees.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredTestaments: [Book] {
        if searchText.isEmpty {
            return bibleData.testaments
        } else {
            return bibleData.testaments.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredSecondEnoch: [Book] {
        if searchText.isEmpty {
            return bibleData.secondEnoch
        } else {
            return bibleData.secondEnoch.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredDidache: [Book] {
        if searchText.isEmpty {
            return bibleData.didache
        } else {
            return bibleData.didache.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var filteredFirstClement: [Book] {
        if searchText.isEmpty {
            return bibleData.firstClement
        } else {
            return bibleData.firstClement.filter { $0.name.lowercased().contains(searchText.lowercased()) }
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
                    // Old Testament Section
                    Section(header: Text("Old Testament")) {
                        if showThematicGrouping {
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
                        } else {
                            flatBookList(filteredOldTestament, canonicalOrder: Testament.oldNames)
                        }
                    }

                    // New Testament Section
                    Section(header: Text("New Testament")) {
                        if showThematicGrouping {
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
                        } else {
                            flatBookList(filteredNewTestament, canonicalOrder: Testament.newNames)
                        }
                    }

                    // Apocrypha Section (Conditional)
                    if showApocrypha && !filteredApocrypha.isEmpty {
                        Section(header: Text("Apocrypha")) {
                            if showThematicGrouping {
                                let deuterocanonical = [
                                    "Tobit", "Judith", "Additions to Esther", "1 Maccabees", "2 Maccabees",
                                    "Wisdom of Solomon", "Ecclesiasticus", "Baruch", "Letter of Jeremiah",
                                    "Prayer of Azariah", "Susanna", "Bel and the Dragon"
                                ]
                                let orthodoxOnly = [
                                    "1 Esdras", "2 Esdras", "Prayer of Manasseh", "Psalm 151", "3 Maccabees", "4 Maccabees"
                                ]

                                groupSection("Deuterocanonical", books: deuterocanonical, within: filteredApocrypha)
                                groupSection("Orthodox only", books: orthodoxOnly, within: filteredApocrypha)
                            } else {
                                flatBookList(filteredApocrypha, canonicalOrder: Testament.apocryphaNames)
                            }
                        }
                    }

                    // Book of Enoch Section (Conditional - same as Apocrypha)
                    if showJewishPseudepigraphaEnoch && !filteredEnoch.isEmpty {
                        Section(header: Text("Jewish Pseudepigrapha (Book of Enoch)")) {
                            ForEach(filteredEnoch, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }

                    // Book of Jubilees Section
                    if showJubilees && !filteredJubilees.isEmpty {
                        Section(header: Text("Book of Jubilees")) {
                            ForEach(filteredJubilees, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }

                    // Testaments of the Twelve Patriarchs Section
                    if showTestaments && !filteredTestaments.isEmpty {
                        Section(header: Text("Testaments of the Twelve Patriarchs")) {
                            ForEach(filteredTestaments, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }

                    // 2 Enoch Section
                    if showSecondEnoch && !filteredSecondEnoch.isEmpty {
                        Section(header: Text("2 Enoch (Secrets of Enoch)")) {
                            ForEach(filteredSecondEnoch, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }

                    // Early Christian Writings
                    if showDidache && !filteredDidache.isEmpty {
                        Section(header: Text("Early Christian Writings (Didache)")) {
                            ForEach(filteredDidache, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }

                    if showFirstClement && !filteredFirstClement.isEmpty {
                        Section(header: Text("Early Christian Writings (1 Clement)")) {
                            ForEach(filteredFirstClement, id: \.name) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    NavigationTitle(name: book.name, description: book.description)
                                }
                                .readingThemeRow(readingTheme)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(readingTheme.isCustom ? .hidden : .automatic)
        }
        .background((readingTheme.isCustom ? readingTheme.backgroundColor(for: colorScheme) : Color.clear).ignoresSafeArea())
        .onAppear {
            fetchBibleData()
            fetchApocryphaData()
            fetchEnochData()
            fetchJubileesData()
            fetchTestamentsData()
            fetchSecondEnochData()
            fetchDidacheData()
            fetchFirstClementData()
        }
            .onChange(of: showApocrypha) { _, newValue in
                if newValue && bibleData.apocrypha.isEmpty {
                    fetchApocryphaData()
                }
            }
            .onChange(of: showJewishPseudepigraphaEnoch) { _, newValue in
                if newValue && bibleData.enoch.isEmpty {
                    fetchEnochData()
                }
            }
            .onChange(of: showJubilees) { _, newValue in
                if newValue && bibleData.jubilees.isEmpty {
                    fetchJubileesData()
                }
            }
            .onChange(of: showTestaments) { _, newValue in
                if newValue && bibleData.testaments.isEmpty {
                    fetchTestamentsData()
                }
            }
            .onChange(of: showSecondEnoch) { _, newValue in
                if newValue && bibleData.secondEnoch.isEmpty {
                    fetchSecondEnochData()
                }
            }
            .onChange(of: showDidache) { _, newValue in
                if newValue && bibleData.didache.isEmpty {
                    fetchDidacheData()
                }
            }
            .onChange(of: showFirstClement) { _, newValue in
                if newValue && bibleData.firstClement.isEmpty {
                    fetchFirstClementData()
                }
            }
            .onChange(of: appViewModel.selectedVersion) { _, _ in
                fetchBibleData()
            }
            .navigationTitle("Bible (\(appViewModel.selectedVersion.shortName))")
            .readingThemeNavBar(readingTheme, colorScheme: colorScheme)
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
                .readingThemeRow(readingTheme)
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
                .readingThemeRow(readingTheme)
            }
        }
    }

    @ViewBuilder
    private func flatBookList(_ books: [Book], canonicalOrder: [String]) -> some View {
        let orderedBooks = booksInOrder(names: canonicalOrder, available: books)
        ForEach(orderedBooks, id: \.name) { book in
            NavigationLink(destination: BookDetailView(book: book)) {
                NavigationTitle(name: book.name, description: book.description)
            }
            .readingThemeRow(readingTheme)
        }
    }

    // Fetch Bible Data (Old and New Testament)
    private func fetchBibleData() {
        let fetchedData = BibleService.shared.fetchBibleData(version: appViewModel.selectedVersion)
        bibleData.oldTestament = fetchedData.oldTestament
        bibleData.newTestament = fetchedData.newTestament
        appViewModel.allBibleData = bibleData.oldTestament + bibleData.newTestament
    }

    // Fetch Apocrypha Data
    private func fetchApocryphaData() {
        let fetchedApocrypha = BibleService.shared.fetchApocryphaData()
        bibleData.apocrypha = fetchedApocrypha
        appendToAllBibleData(fetchedApocrypha)
    }

    // Fetch Enoch Data
    private func fetchEnochData() {
        let fetchedEnoch = BibleService.shared.fetchEnochData()
        bibleData.enoch = fetchedEnoch
        appendToAllBibleData(fetchedEnoch)
    }

    // Fetch Jubilees Data
    private func fetchJubileesData() {
        let fetched = BibleService.shared.fetchJubileesData()
        bibleData.jubilees = fetched
        appendToAllBibleData(fetched)
    }

    // Fetch Testaments Data
    private func fetchTestamentsData() {
        let fetched = BibleService.shared.fetchTestamentsData()
        bibleData.testaments = fetched
        appendToAllBibleData(fetched)
    }

    // Fetch 2 Enoch Data
    private func fetchSecondEnochData() {
        let fetched = BibleService.shared.fetchSecondEnochData()
        bibleData.secondEnoch = fetched
        appendToAllBibleData(fetched)
    }

    // Fetch Didache Data
    private func fetchDidacheData() {
        let fetched = BibleService.shared.fetchDidacheData()
        bibleData.didache = fetched
        appendToAllBibleData(fetched)
    }

    // Fetch 1 Clement Data
    private func fetchFirstClementData() {
        let fetched = BibleService.shared.fetchFirstClementData()
        bibleData.firstClement = fetched
        appendToAllBibleData(fetched)
    }

    private func appendToAllBibleData(_ books: [Book]) {
        if let allBibleData = appViewModel.allBibleData {
            if allBibleData.isEmpty {
                appViewModel.allBibleData = books
            } else {
                appViewModel.allBibleData?.append(contentsOf: books)
            }
        } else {
            appViewModel.allBibleData = books
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
