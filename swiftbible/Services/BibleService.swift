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

    private let baseURL = Bundle.main.url(forResource: "bible", withExtension: "json")!

    func fetchBibleData() -> (oldTestament: [Book], newTestament: [Book]) {
        do {
            let data = try Data(contentsOf: baseURL)
            let decoder = JSONDecoder()
            var bibleData = try decoder.decode([Book].self, from: data)

            for i in bibleData.indices {
                if Testament.oldNames.contains(bibleData[i].name) {
                    bibleData[i].testament = .old
                } else if Testament.newNames.contains(bibleData[i].name) {
                    bibleData[i].testament = .new
                }
            }
            let oldTestament = bibleData.filter { $0.testament == .old }
            let newTestament = bibleData.filter { $0.testament == .new }

            // print("Got Bible data \((oldTestament, newTestament))")
            return (oldTestament, newTestament)
        } catch {
            print("Error fetching Bible data: \(error)")
            return ([], [])
        }
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
