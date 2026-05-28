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

    func enqueue(_ badge: BadgeDefinition) {
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
