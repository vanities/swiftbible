//
//  DailyDevotional.swift
//  swiftbible
//
//  Model representing a daily devotional message
//

import Foundation

struct DailyDevotional: Codable {
    let id: Int
    let message: String
    let for_date: String
    let devotional_type: String?
}
