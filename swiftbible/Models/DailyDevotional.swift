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
    let series_name: String?
    let series_part: Int?
    let holiday_name: String?
    let holiday_url: String?
    let anchor_verse: String?
}
