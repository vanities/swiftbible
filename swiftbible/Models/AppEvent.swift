//
//  AppEvent.swift
//  swiftbible
//
//  In-app event model. Surfaces a date-gated card in MoreView so users
//  can return to an active App Store In-App Event after dismissing it.
//  Add new entries to AppEventRegistry.allEvents — they auto-show during
//  their date window and disappear after.
//

import SwiftUI

struct AppEvent: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let iconName: String   // SF Symbol
    let accent: AppEventAccent
    let startDate: Date
    let endDate: Date
    let action: AppEventAction

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

enum AppEventAccent: Equatable {
    case gold
    case red
    case accent

    var color: Color {
        switch self {
        case .gold: return .brandGold
        case .red: return .brandRedDark
        case .accent: return .brandAccent
        }
    }
}

enum AppEventAction: Equatable {
    /// Open a specific verse via AppViewModel.navigateToVerse.
    case openVerse(book: String, chapter: Int, verse: Int)
    /// Just switch tabs (e.g., to dailyDevotional).
    case openTab(Tabs)
}

/// Static registry of all events the app knows about. Edit `allEvents` to
/// add or remove. The MoreView shows only entries currently within their
/// date window.
enum AppEventRegistry {

    static let pentecost2026 = AppEvent(
        id: "pentecost-2026",
        name: "Pentecost Reading Plan",
        subtitle: "Acts 2 — through June 7",
        iconName: "flame.fill",
        accent: .gold,
        startDate: parseISO("2026-05-25T00:00:00Z"),
        endDate: parseISO("2026-06-07T23:59:59Z"),
        action: .openVerse(book: "Acts", chapter: 2, verse: 1)
    )

    /// All known events. Add new ones here.
    static let allEvents: [AppEvent] = [
        pentecost2026
    ]

    /// Events currently within their date window.
    static var activeEvents: [AppEvent] {
        allEvents.filter(\.isActive)
    }

    private static func parseISO(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s) ?? .distantFuture
    }
}
