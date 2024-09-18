//
//  ContentView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI
import StoreKit


struct BibleView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(\.requestReview) var requestReview

    @State private var bibleData: (oldTestament: [Book], newTestament: [Book]) = ([], [])
    @State private var searchText = ""

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

    var body: some View {
        @Bindable var appViewModel = appViewModel
        
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.horizontal)

                List {
                    Section(header: Text("Old Testament")) {
                        ForEach(filteredOldTestament, id: \.name) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                NavigationTitle(name: book.name, description: book.description)
                            }
                        }
                    }

                    Section(header: Text("New Testament")) {
                        ForEach(filteredNewTestament, id: \.name) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                NavigationTitle(name: book.name, description: book.description)
                            }
                        }
                    }
                }
            }
            .onAppear {
                if bibleData.newTestament.isEmpty {
                    bibleData = BibleService.shared.fetchBibleData()
                    appViewModel.allBibleData = bibleData.oldTestament + bibleData.newTestament
                }
                requestReview()
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
        }
    }
}

#Preview {
    BibleView()
        .environment(UserViewModel())
}
