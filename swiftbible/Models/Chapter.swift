//
//  Chapter.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/10/24.
//


struct Chapter: Codable, Equatable, Hashable {
    static func == (lhs: Chapter, rhs: Chapter) -> Bool {
        lhs.number == rhs.number
    }

    let number: Int
    let paragraphs: [Paragraph]

    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
}