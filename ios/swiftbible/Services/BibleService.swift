//
//  BibleService.swift
//  swiftbible
//
//  Created on 9/1/24.
//

import Foundation

// MARK: - BibleService
class BibleService {
    static let shared = BibleService()

    enum LoadError: Error {
        case missingResource(String)
    }

    // Cache parsed Bible data by version to avoid re-parsing JSON
    private var cache: [Version: [Book]] = [:]
    // Standalone collections (Apocrypha, Enoch, …) cached by resource name
    private var collectionCache: [String: [Book]] = [:]

    private func loadBibleData(version: Version) -> [Book] {
        // Return cached data if available
        if let cached = cache[version] {
            return cached
        }

        // Original version loads Hebrew OT + Greek NT from separate files
        if version == .original {
            return loadOriginalData()
        }

        guard let url = Bundle.main.url(forResource: version.filename, withExtension: "json") else {
            print("Error: Could not find \(version.filename).json")
            SentryService.shared.capture(LoadError.missingResource(version.filename), context: [
                "service": "BibleService",
                "operation": "load_bible",
                "version": version.rawValue
            ])
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var bibleData = try decoder.decode([Book].self, from: data)

            for i in bibleData.indices {
                bibleData[i].version = version
                if Testament.oldNames.contains(bibleData[i].name) {
                    bibleData[i].testament = .old
                } else if Testament.newNames.contains(bibleData[i].name) {
                    bibleData[i].testament = .new
                }
            }

            // Cache the result
            cache[version] = bibleData
            return bibleData
        } catch {
            print("Error fetching Bible data: \(error)")
            SentryService.shared.capture(error, context: [
                "service": "BibleService",
                "operation": "load_bible",
                "version": version.rawValue
            ])
            return []
        }
    }

    private func loadOriginalData() -> [Book] {
        var bibleData: [Book] = []

        // Hebrew OT + Greek NT, each stamped with its testament
        let hebrewBooks = decodeBooks(resource: "hebrew", operation: "load_original_hebrew")
        bibleData.append(contentsOf: stamped(hebrewBooks, version: .original, testament: .old))

        let greekBooks = decodeBooks(resource: "greek", operation: "load_original_greek")
        bibleData.append(contentsOf: stamped(greekBooks, version: .original, testament: .new))

        cache[.original] = bibleData
        return bibleData
    }

    private func stamped(_ books: [Book], version: Version, testament: Testament) -> [Book] {
        var books = books
        for i in books.indices {
            books[i].version = version
            books[i].testament = testament
        }
        return books
    }

    /// Decodes a bundled `[Book]` JSON resource, reporting failures to Sentry.
    private func decodeBooks(resource: String, operation: String) -> [Book] {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            print("Error: Could not find \(resource).json")
            SentryService.shared.capture(LoadError.missingResource(resource), context: [
                "service": "BibleService",
                "operation": operation,
                "resource": resource
            ])
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Book].self, from: data)
        } catch {
            print("Error fetching \(resource) data: \(error)")
            SentryService.shared.capture(error, context: [
                "service": "BibleService",
                "operation": operation,
                "resource": resource
            ])
            return []
        }
    }

    func fetchBibleData(version: Version = .kjv) -> (oldTestament: [Book], newTestament: [Book]) {
        let bibleData = loadBibleData(version: version)
        let oldTestament = bibleData.filter { $0.testament == .old }
        let newTestament = bibleData.filter { $0.testament == .new }
        return (oldTestament, newTestament)
    }

    func fetchBook(named bookName: String, version: Version = .kjv) -> Book? {
        let bibleData = loadBibleData(version: version)
        if let canonicalBook = bibleData.first(where: { $0.name == bookName }) {
            return canonicalBook
        }

        // Apocrypha and Enoch are independent from selected translation files,
        // so always fall back to their dedicated sources.
        if let apocryphaBook = fetchApocryphaData().first(where: { $0.name == bookName }) {
            return apocryphaBook
        }

        if let enochBook = fetchEnochData().first(where: { $0.name == bookName }) {
            return enochBook
        }

        if let jubileesBook = fetchJubileesData().first(where: { $0.name == bookName }) {
            return jubileesBook
        }

        if let testamentsBook = fetchTestamentsData().first(where: { $0.name == bookName }) {
            return testamentsBook
        }

        if let secondEnochBook = fetchSecondEnochData().first(where: { $0.name == bookName }) {
            return secondEnochBook
        }

        if let didacheBook = fetchDidacheData().first(where: { $0.name == bookName }) {
            return didacheBook
        }

        return fetchFirstClementData().first(where: { $0.name == bookName })
    }

    // MARK: - Standalone collections

    /// Loads a standalone collection from its bundled JSON, stamping every
    /// book with the given testament. Cached per resource name.
    private func loadCollection(resource: String, testament: Testament) -> [Book] {
        if let cached = collectionCache[resource] {
            return cached
        }

        var books = decodeBooks(resource: resource, operation: "load_collection")
        guard !books.isEmpty else { return [] }

        for i in books.indices {
            books[i].testament = testament
        }

        collectionCache[resource] = books
        return books
    }

    func fetchApocryphaData() -> [Book] {
        loadCollection(resource: "apocrypha", testament: .apocrypha)
    }

    func fetchEnochData() -> [Book] {
        loadCollection(resource: "enoch", testament: .enoch)
    }

    func fetchJubileesData() -> [Book] {
        loadCollection(resource: "jubilees", testament: .jubilees)
    }

    func fetchTestamentsData() -> [Book] {
        loadCollection(resource: "testaments12", testament: .testaments)
    }

    func fetchSecondEnochData() -> [Book] {
        loadCollection(resource: "2enoch", testament: .secondEnoch)
    }

    func fetchDidacheData() -> [Book] {
        loadCollection(resource: "didache", testament: .didache)
    }

    func fetchFirstClementData() -> [Book] {
        loadCollection(resource: "1clement", testament: .firstClement)
    }
}
