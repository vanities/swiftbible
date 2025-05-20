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

    @State private var bibleData: (oldTestament: [Book], newTestament: [Book], apocrypha: [Book]) = ([], [], [])
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
                        ForEach(filteredOldTestament, id: \.name) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                NavigationTitle(name: book.name, description: book.description)
                            }
                        }
                    }

                    // New Testament Section
                    Section(header: Text("New Testament")) {
                        ForEach(filteredNewTestament, id: \.name) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                NavigationTitle(name: book.name, description: book.description)
                            }
                        }
                    }

                    // Apocrypha Section (Conditional)
                    if showApocrypha && !filteredApocrypha.isEmpty {
                        Section(header: Text("Apocrypha")) {
                            ForEach(filteredApocrypha, id: \.name) { book in
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
                requestReview()
            }
            .onChange(of: showApocrypha) { newValue in
                if newValue && bibleData.apocrypha.isEmpty {
                    fetchApocryphaData()
                } else if !newValue {
                    // Optionally, clear Apocrypha data when hidden
                    // bibleData.apocrypha = []
                }
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
