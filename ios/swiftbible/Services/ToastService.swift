//
//  ToastService.swift
//  swiftbible
//

import Foundation
import SwiftUI

/// App-wide queue of badge-earned toasts. ContentView observes the queue
/// and renders the head item as a top-of-screen banner, advancing as
/// the user (or the auto-dismiss timer) dismisses each one. This lets
/// a badge earned mid-chapter or mid-devotional show immediately, not
/// only when the user happens to open the Progress tab next.
@MainActor
@Observable
final class ToastService {
    static let shared = ToastService()

    private(set) var queue: [BadgeDefinition] = []

    private init() {}

    /// User opt-out for badge-earned celebration toasts (and the confetti that
    /// rides on the queue growing). Defaults to on. Read from UserDefaults so
    /// this non-View service honors the @AppStorage("showAchievementToasts")
    /// toggle; a missing key means the user hasn't opted out → enabled.
    static let achievementToastsKey = "showAchievementToasts"

    private var achievementToastsEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.achievementToastsKey) as? Bool ?? true
    }

    func enqueue(_ badge: BadgeDefinition) {
        // Badges are still earned + recorded when toasts are off; we just skip
        // the celebration. The badge remains visible in the badge gallery.
        guard achievementToastsEnabled else { return }
        // Avoid duplicates if BadgeService fires twice in quick succession
        // (e.g. scenePhase + chapter onAppear back to back).
        guard !queue.contains(where: { $0.id == badge.id }) else { return }
        queue.append(badge)
    }

    func dismissFirst() {
        guard !queue.isEmpty else { return }
        queue.removeFirst()
    }

    #if DEBUG
    /// Synthetic toast for QA. Picks a known badge so the UI shows real
    /// colors/copy. Cycles through several so repeat taps look different.
    func enqueueDebugSample() {
        let samples: [String] = [
            "tier.streak.bronze",
            "collect.gospels",
            "hidden.night.owl",
            "tier.books.gold"
        ]
        let id = samples[debugIndex % samples.count]
        debugIndex += 1
        if let def = BadgeRegistry.definition(forId: id) {
            enqueue(def)
        }
    }

    private var debugIndex = 0
    #endif
}
