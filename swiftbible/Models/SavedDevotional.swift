//
//  SavedDevotional.swift
//  swiftbible
//
//  Created on 2/15/25.
//

import Foundation
import SwiftData

@Model
final class SavedDevotional: Identifiable {
    var date: Date
    var message: String
    var created: Date

    init(date: Date, message: String, created: Date = Date()) {
        self.date = date
        self.message = message
        self.created = created
    }
}
