//
//  EarnedBadge.swift
//  swiftbible
//

import Foundation
import SwiftData

/// One row per badge a user has earned. `notified` lets the UI show a
/// one-time "you earned this" toast on the next ProgressView open, then
/// flips to true so it doesn't re-trigger.
@Model
final class EarnedBadge {
    // No @Attribute(.unique): the app's SwiftData store is CloudKit-backed
    // (iCloud entitlement → automatic CloudKit), and CloudKit forbids unique
    // constraints — a unique attribute makes the entire store fail to load,
    // silently breaking ALL local persistence. Uniqueness is enforced in code:
    // BadgeService.checkBadges skips badgeIds already present before inserting.
    var badgeId: String = ""
    var earnedAt: Date = Date()
    var notified: Bool = false

    init(badgeId: String, earnedAt: Date = Date(), notified: Bool = false) {
        self.badgeId = badgeId
        self.earnedAt = earnedAt
        self.notified = notified
    }
}
