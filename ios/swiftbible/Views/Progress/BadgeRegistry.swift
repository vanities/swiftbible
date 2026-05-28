//
//  BadgeRegistry.swift
//  swiftbible
//

import SwiftUI

// MARK: - Domain types

enum BadgeTrack: String, CaseIterable, Codable {
    case streak, chapters, books, devotionals

    var displayName: String {
        switch self {
        case .streak: return "Streak"
        case .chapters: return "Chapters"
        case .books: return "Books"
        case .devotionals: return "Devotionals"
        }
    }

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .chapters: return "book.fill"
        case .books: return "books.vertical.fill"
        case .devotionals: return "sun.horizon.fill"
        }
    }
}

enum BadgeTier: String, CaseIterable, Codable, Comparable {
    case bronze, silver, gold, diamond

    static func < (lhs: BadgeTier, rhs: BadgeTier) -> Bool {
        lhs.order < rhs.order
    }

    private var order: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .diamond: return 3
        }
    }

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .diamond: return "Diamond"
        }
    }

    /// Primary fill color for the medal.
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.78)
        case .gold: return Color(red: 1.00, green: 0.84, blue: 0.20)
        case .diamond: return Color(red: 0.75, green: 0.95, blue: 1.00)
        }
    }

    /// Secondary color used for gradients/shimmer.
    var accent: Color {
        switch self {
        case .bronze: return Color(red: 0.55, green: 0.30, blue: 0.10)
        case .silver: return Color(red: 0.55, green: 0.55, blue: 0.60)
        case .gold: return Color(red: 0.75, green: 0.55, blue: 0.05)
        case .diamond: return Color(red: 0.45, green: 0.75, blue: 0.95)
        }
    }
}

enum BadgeCategory: String, Codable {
    /// Track-based progression — Bronze through Diamond.
    case tier
    /// Always-visible single-shot achievement (e.g. "All Four Gospels").
    case collectible
    /// Hidden until earned (e.g. "Night Owl").
    case hidden
}

struct BadgeDefinition: Identifiable, Hashable {
    let id: String
    let category: BadgeCategory
    let name: String
    let description: String
    let icon: String
    /// Tint when displayed in color (earned or always-visible).
    let tint: Color
    /// For tier badges: which track + tier this represents.
    let track: BadgeTrack?
    let tier: BadgeTier?
    /// For tier badges: the threshold needed (e.g. 30 for Silver Streak).
    let threshold: Int?

    static func == (lhs: BadgeDefinition, rhs: BadgeDefinition) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Registry

enum BadgeRegistry {
    static let all: [BadgeDefinition] = tiers + collectibles + hidden

    // MARK: Tier ladders (16)

    static let tiers: [BadgeDefinition] = BadgeTrack.allCases.flatMap { track in
        BadgeTier.allCases.map { tier in
            BadgeDefinition(
                id: "tier.\(track.rawValue).\(tier.rawValue)",
                category: .tier,
                name: "\(tier.displayName) \(track.displayName)",
                description: tierDescription(track: track, tier: tier),
                icon: track.icon,
                tint: tier.color,
                track: track,
                tier: tier,
                threshold: threshold(track: track, tier: tier)
            )
        }
    }

    static func threshold(track: BadgeTrack, tier: BadgeTier) -> Int {
        switch (track, tier) {
        case (.streak, .bronze): return 7
        case (.streak, .silver): return 30
        case (.streak, .gold): return 100
        case (.streak, .diamond): return 365

        case (.chapters, .bronze): return 50
        case (.chapters, .silver): return 250
        case (.chapters, .gold): return 1000
        case (.chapters, .diamond): return 1189 // every chapter in the Protestant canon

        case (.books, .bronze): return 5
        case (.books, .silver): return 20
        case (.books, .gold): return 50
        case (.books, .diamond): return 66

        case (.devotionals, .bronze): return 30
        case (.devotionals, .silver): return 100
        case (.devotionals, .gold): return 365
        case (.devotionals, .diamond): return 1000
        }
    }

    private static func tierDescription(track: BadgeTrack, tier: BadgeTier) -> String {
        let value = threshold(track: track, tier: tier)
        switch track {
        case .streak: return "Read \(value) days in a row"
        case .chapters: return "Read \(value) chapters"
        case .books: return "Complete \(value) books"
        case .devotionals: return "View \(value) devotionals"
        }
    }

    // MARK: Visible collectibles (9)

    static let collectibles: [BadgeDefinition] = [
        BadgeDefinition(
            id: "collect.gospels",
            category: .collectible,
            name: "All Four Gospels",
            description: "Read Matthew, Mark, Luke, and John end to end",
            icon: "cross.fill",
            tint: .brandRed,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.pentateuch",
            category: .collectible,
            name: "The Pentateuch",
            description: "Complete the five books of Moses",
            icon: "scroll.fill",
            tint: .brandGold,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.major.prophets",
            category: .collectible,
            name: "Major Prophets",
            description: "Isaiah, Jeremiah, Lamentations, Ezekiel, Daniel",
            icon: "flame.circle.fill",
            tint: .brandAccent,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.minor.prophets",
            category: .collectible,
            name: "Minor Prophets",
            description: "All twelve, Hosea through Malachi",
            icon: "wind",
            tint: .brandPeridot,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.pauline",
            category: .collectible,
            name: "Pauline Epistles",
            description: "All thirteen letters of Paul",
            icon: "envelope.fill",
            tint: .brandRedDark,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.wisdom",
            category: .collectible,
            name: "Wisdom Books",
            description: "Job, Psalms, Proverbs, Ecclesiastes, Song of Solomon",
            icon: "lightbulb.fill",
            tint: .brandGoldLight,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.enoch",
            category: .collectible,
            name: "Enoch Complete",
            description: "Read all five sections of the Book of Enoch",
            icon: "sparkles",
            tint: .cyan,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.apocrypha",
            category: .collectible,
            name: "Apocrypha Complete",
            description: "Read every deuterocanonical book",
            icon: "books.vertical.circle.fill",
            tint: .indigo,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "collect.whole.counsel",
            category: .collectible,
            name: "Whole Counsel",
            description: "Read every book of the Protestant canon at least once",
            icon: "checkmark.seal.fill",
            tint: .brandPeridot,
            track: nil, tier: nil, threshold: nil
        )
    ]

    // MARK: Hidden achievements (10)

    static let hidden: [BadgeDefinition] = [
        BadgeDefinition(
            id: "hidden.night.owl",
            category: .hidden,
            name: "Night Owl",
            description: "Read between midnight and 3 a.m.",
            icon: "moon.stars.fill",
            tint: .indigo,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.early.bird",
            category: .hidden,
            name: "Early Bird",
            description: "Read before 6 a.m.",
            icon: "sunrise.fill",
            tint: .orange,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.marathon",
            category: .hidden,
            name: "Marathon",
            description: "Read ten or more chapters in a single day",
            icon: "figure.run",
            tint: .brandAccent,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.pentecost",
            category: .hidden,
            name: "Pentecost",
            description: "Read Acts 2 on Pentecost Sunday",
            icon: "flame.fill",
            tint: .brandGold,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.resurrection.sunday",
            category: .hidden,
            name: "Resurrection Sunday",
            description: "Read on Easter morning",
            icon: "sun.max.fill",
            tint: .brandGoldLight,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.christmas.story",
            category: .hidden,
            name: "Christmas Story",
            description: "Read Luke 2 on Christmas Day",
            icon: "star.fill",
            tint: .brandRed,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.all.voices",
            category: .hidden,
            name: "All Voices",
            description: "View all four AI devotional tracks in one week",
            icon: "person.3.fill",
            tint: .brandAccent,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.series.completionist",
            category: .hidden,
            name: "Series Completionist",
            description: "Finish a full four-week Sunday devotional series",
            icon: "rosette",
            tint: .brandGold,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.phoenix",
            category: .hidden,
            name: "Phoenix",
            description: "Recover a streak after a freeze",
            icon: "flame.circle.fill",
            tint: .orange,
            track: nil, tier: nil, threshold: nil
        ),
        BadgeDefinition(
            id: "hidden.late.wisdom",
            category: .hidden,
            name: "Late Wisdom",
            description: "Read Proverbs after 10 p.m.",
            icon: "owl",
            tint: .purple,
            track: nil, tier: nil, threshold: nil
        )
    ]

    // MARK: Lookup helpers

    static func definition(forId id: String) -> BadgeDefinition? {
        all.first(where: { $0.id == id })
    }

    static func tier(track: BadgeTrack, tier: BadgeTier) -> BadgeDefinition {
        // Force-unwrap is safe: the tier ladder is generated from every
        // (track, tier) pair, so a matching definition always exists.
        return tiers.first { $0.track == track && $0.tier == tier }!
    }
}
