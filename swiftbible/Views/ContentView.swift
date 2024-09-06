//
//  ContentView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
//

import SwiftUI


struct ContentView: View {
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
        NavigationStack {
            VStack {
                SearchBar(text: $searchText)

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
            .onAppear {
                if bibleData.newTestament.isEmpty {
                    bibleData = BibleService.shared.fetchBibleData()
                }
            }
            .navigationTitle("Bible")
            .navigationBarItems(trailing: settingsButton)
            .navigationDestination(for: String.self) { value in
                if value == "settings" {
                    SettingsView()
                }
            }
            .ignoresSafeArea(.all, edges: .horizontal)
            .onAppear {
                Task {
                    await SupabaseService.shared.refreshToken()
                }
            }
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

    var settingsButton: some View {
        NavigationLink(value: "settings") {
            Image(systemName: Constants.settingsIcon)
                .foregroundColor(Color.primary)
        }
    }

    struct Constants {
        static let settingsIcon = "gear"
    }
}

#Preview {
    ContentView()
}
