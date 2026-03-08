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

        return fetchEnochData().first(where: { $0.name == bookName })
    }

    func fetchApocryphaData() -> [Book] {
        do {
            let apocryphaURL = Bundle.main.url(forResource: "apocrypha", withExtension: "json")!
            let data = try Data(contentsOf: apocryphaURL)
            let decoder = JSONDecoder()
            var apocryphaData = try decoder.decode([Book].self, from: data)

            for i in apocryphaData.indices {
                apocryphaData[i].testament = .apocrypha
            }

            // print("Got Apocrypha data: \(apocryphaData)")
            return apocryphaData
        } catch {
            print("Error fetching Apocrypha data: \(error)")
            return []
        }
    }

    func fetchEnochData() -> [Book] {
        do {
            let enochURL = Bundle.main.url(forResource: "enoch", withExtension: "json")!
            let data = try Data(contentsOf: enochURL)
            let decoder = JSONDecoder()
            var enochData = try decoder.decode([Book].self, from: data)

            for i in enochData.indices {
                enochData[i].testament = .enoch
            }

            // print("Got Enoch data: \(enochData)")
            return enochData
        } catch {
            print("Error fetching Enoch data: \(error)")
            return []
        }
    }
}
