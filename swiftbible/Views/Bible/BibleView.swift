//
//  ContentView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI


struct BibleView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @AppStorage("fontName") private var fontName: String = "Helvetica"
    @AppStorage("fontSize") private var fontSize: Int = 20

    @Environment(UserViewModel.self) private var userViewModel

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
                                Title(book.name, book.description)
                            }
                        }
                    }

                    Section(header: Text("New Testament")) {
                        ForEach(filteredNewTestament, id: \.name) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                Title(book.name, book.description)
                            }
                        }
                    }
                }
            }
            .font(Font.custom(fontName, size: CGFloat(fontSize)))
            .onAppear {
                if bibleData.newTestament.isEmpty {
                    bibleData = BibleService.shared.fetchBibleData()
                    appViewModel.allBibleData = bibleData.oldTestament + bibleData.newTestament
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
        }
    }

    func Title(_ name: String, _ description: String) -> some View {
        VStack(alignment: .leading) {
            Text(name)
            Text(description)
                .font(.footnote)
                .fontWeight(.light)
        }
    }
}

#Preview {
    BibleView()
        .environment(UserViewModel())
}
