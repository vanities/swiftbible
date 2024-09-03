//
//  BibleService.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/1/24.
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
                }
                else if Testament.newNames.contains(bibleData[i].name) {
                    bibleData[i].testament = .new
                }
            }
            let oldTestament = bibleData.filter { $0.testament == .old }
            let newTestament = bibleData.filter { $0.testament == .new }

            print("Got Bible data \((oldTestament, newTestament))")
            return (oldTestament, newTestament)
        } catch {
            print("Error fetching Bible data: \(error)")
            return ([], [])
        }
    }
}
