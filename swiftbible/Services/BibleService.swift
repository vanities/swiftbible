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

    // Cache parsed Bible data by version to avoid re-parsing JSON
    private var cache: [Version: [Book]] = [:]
    private var apocryphaCache: [Book]?
    private var enochCache: [Book]?
    private var jubileesCache: [Book]?
    private var testamentsCache: [Book]?
    private var secondEnochCache: [Book]?
    private var didacheCache: [Book]?
    private var firstClementCache: [Book]?

    private func loadBibleData(version: Version) -> [Book] {
        // Return cached data if available
        if let cached = cache[version] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: version.filename, withExtension: "json") else {
            print("Error: Could not find \(version.filename).json")
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

    func fetchApocryphaData() -> [Book] {
        if let apocryphaCache {
            return apocryphaCache
        }

        do {
            let apocryphaURL = Bundle.main.url(forResource: "apocrypha", withExtension: "json")!
            let data = try Data(contentsOf: apocryphaURL)
            let decoder = JSONDecoder()
            var apocryphaData = try decoder.decode([Book].self, from: data)

            for i in apocryphaData.indices {
                apocryphaData[i].testament = .apocrypha
            }

            apocryphaCache = apocryphaData
            return apocryphaData
        } catch {
            print("Error fetching Apocrypha data: \(error)")
            return []
        }
    }

    func fetchEnochData() -> [Book] {
        if let enochCache {
            return enochCache
        }

        do {
            let enochURL = Bundle.main.url(forResource: "enoch", withExtension: "json")!
            let data = try Data(contentsOf: enochURL)
            let decoder = JSONDecoder()
            var enochData = try decoder.decode([Book].self, from: data)

            for i in enochData.indices {
                enochData[i].testament = .enoch
            }

            enochCache = enochData
            return enochData
        } catch {
            print("Error fetching Enoch data: \(error)")
            return []
        }
    }

    func fetchJubileesData() -> [Book] {
        if let jubileesCache {
            return jubileesCache
        }

        do {
            let url = Bundle.main.url(forResource: "jubilees", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var jubileesData = try decoder.decode([Book].self, from: data)

            for i in jubileesData.indices {
                jubileesData[i].testament = .jubilees
            }

            jubileesCache = jubileesData
            return jubileesData
        } catch {
            print("Error fetching Jubilees data: \(error)")
            return []
        }
    }

    func fetchTestamentsData() -> [Book] {
        if let testamentsCache {
            return testamentsCache
        }

        do {
            let url = Bundle.main.url(forResource: "testaments12", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var testamentsData = try decoder.decode([Book].self, from: data)

            for i in testamentsData.indices {
                testamentsData[i].testament = .testaments
            }

            testamentsCache = testamentsData
            return testamentsData
        } catch {
            print("Error fetching Testaments data: \(error)")
            return []
        }
    }

    func fetchSecondEnochData() -> [Book] {
        if let secondEnochCache {
            return secondEnochCache
        }

        do {
            let url = Bundle.main.url(forResource: "2enoch", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var secondEnochData = try decoder.decode([Book].self, from: data)

            for i in secondEnochData.indices {
                secondEnochData[i].testament = .secondEnoch
            }

            secondEnochCache = secondEnochData
            return secondEnochData
        } catch {
            print("Error fetching 2 Enoch data: \(error)")
            return []
        }
    }

    func fetchDidacheData() -> [Book] {
        if let didacheCache {
            return didacheCache
        }

        do {
            let url = Bundle.main.url(forResource: "didache", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var didacheData = try decoder.decode([Book].self, from: data)

            for i in didacheData.indices {
                didacheData[i].testament = .didache
            }

            didacheCache = didacheData
            return didacheData
        } catch {
            print("Error fetching Didache data: \(error)")
            return []
        }
    }

    func fetchFirstClementData() -> [Book] {
        if let firstClementCache {
            return firstClementCache
        }

        do {
            let url = Bundle.main.url(forResource: "1clement", withExtension: "json")!
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            var firstClementData = try decoder.decode([Book].self, from: data)

            for i in firstClementData.indices {
                firstClementData[i].testament = .firstClement
            }

            firstClementCache = firstClementData
            return firstClementData
        } catch {
            print("Error fetching 1 Clement data: \(error)")
            return []
        }
    }
}
