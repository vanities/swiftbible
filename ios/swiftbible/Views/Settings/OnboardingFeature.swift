//
//  OnboardingFeature.swift
//  swiftbible
//
//  The feature catalog behind the onboarding flow, plus the UserDefaults
//  bookkeeping that decides full-tour vs "What's New" spotlight.
//

import Foundation

// MARK: - Feature Tracking

/// Features that are introduced via the onboarding flow.
///
/// Add a new case when shipping a feature worth spotlighting. Existing users
/// who have already seen older features will be shown only the new ones as a
/// "What's New" sheet; new installs see every case as a full onboarding.
enum OnboardingFeature: String, CaseIterable, Identifiable {
    case welcome
    case dailyReminder
    case achievements
    case watchApp
    case widget
    case explain

    var id: String { rawValue }

    /// Cases the current device can actually benefit from. `.explain` is
    /// hidden on hardware/OS that cannot run Apple Intelligence — showing
    /// the page there would tease a feature the user can never use.
    ///
    /// `@MainActor` because `AppleFoundationModelService.availabilityStatus`
    /// is MainActor-isolated. All real call sites (SwiftUI bodies,
    /// `evaluateOnboarding`) are already on the main actor.
    @MainActor
    static var availableCases: [OnboardingFeature] {
        allCases.filter { $0.isSupportedOnThisDevice }
    }

    @MainActor
    var isSupportedOnThisDevice: Bool {
        switch self {
        case .explain:
            // Strict gate: only show when Apple Intelligence is actually
            // ready on this hardware. This covers both unsupported OS and
            // unsupported hardware (e.g. pre-A17 iPhones). If the model is
            // temporarily unavailable (downloading, not enabled yet), we
            // hide the page this launch — the user will see it as a
            // What's-New spotlight the next time they open the app.
            return AppleFoundationModelService.shared.availabilityStatus.isReadyForGeneration
        default:
            return true
        }
    }

    /// Identity-led, action-oriented page titles.
    /// (Identity-Based Motivation — "I am someone who reads scripture daily.")
    var title: String {
        switch self {
        case .welcome: return String(localized: "Make Scripture part of your day")
        case .dailyReminder: return String(localized: "A gentle nudge, on your schedule")
        case .achievements: return String(localized: "Celebrate your progress")
        case .watchApp: return String(localized: "Scripture on your wrist")
        case .widget: return String(localized: "Today's verse, every unlock")
        case .explain: return String(localized: "Ask the text. Go deeper.")
        }
    }

    /// Subtitles use Tiny Habits framing ("after X, do Y") for the feature
    /// pages so the new behaviour is anchored to an existing routine.
    var subtitle: String {
        switch self {
        case .welcome:
            return String(localized: "A quiet space to read, reflect, and return — designed to keep you in the Word.")
        case .dailyReminder:
            return String(localized: "Pick a time that fits your day — morning coffee, evening wind-down — and we'll send a gentle reminder to open today's devotional.")
        case .achievements:
            return String(localized: "As you read, you'll build streaks and unlock badges for milestones along the way. We celebrate each one with a little banner — switch those off anytime in Settings.")
        case .watchApp:
            return String(localized: "After you check the time, glance at today's devotional. A tiny moment, every day.")
        case .widget:
            return String(localized: "Every time you unlock your phone, today's reading is waiting on your Home Screen.")
        case .explain:
            return String(localized: "Tap any verse for an AI explanation, then ask follow-up questions. Powered by Apple Intelligence — on-device and private.")
        }
    }

    var imageName: String? {
        switch self {
        case .welcome: return "Icon-Classic-Preview" // Halo Effect — strong brand impression
        case .dailyReminder: return nil // animated SF Symbol hero
        case .achievements: return nil // layered SF Symbol hero
        case .watchApp: return "OnboardingWatch"
        case .widget: return "OnboardingWidget"
        case .explain: return nil // video hero
        }
    }

    /// A short snippet rendered as a "gift" on the welcome page (Reciprocity).
    ///
    /// Strategy:
    /// 1. Try today's cached devotional — if present, parse the heading
    ///    (e.g. `Luke 3:7-8: Fruits Worthy of Repentance`) and a short
    ///    body snippet from the existing `message` field. This is fresh
    ///    daily and matches what the user sees in the Devotional tab.
    /// 2. Fall back to a small hand-curated pool keyed to day-of-year so
    ///    new installs (no cache yet) and replays still get something fresh.
    var welcomeVerse: (text: String, reference: String)? {
        switch self {
        case .welcome:
            return Self.todaysDevotionalSnippet()
                ?? Self.dailyWelcomeVerse(for: Date())
        default:
            return nil
        }
    }

    /// Pull today's cached devotional and parse it into a card-ready snippet.
    /// Mirrors the parsing approach used by the Home Screen widget so the
    /// onboarding card stays in lockstep with what the widget renders.
    static func todaysDevotionalSnippet() -> (text: String, reference: String)? {
        guard let devotional = CacheService.shared.loadDevotional(for: Date()) else {
            return nil
        }
        guard let heading = parseDevotionalHeading(devotional.message) else {
            return nil
        }
        let body = parseDevotionalBody(devotional.message, maxLength: 140)
        // If the body parse failed, surface just the heading as the text and
        // use a generic label as the reference.
        if body.isEmpty {
            return (text: heading, reference: "Today's devotional")
        }
        return (text: body, reference: heading)
    }

    /// Extract the devotional heading line, stripping the leading date.
    /// Input examples:
    ///   "April 12, 2026 — Luke 3:7-8: Fruits Worthy of Repentance\n\n..."
    ///   "## March 30, 2026 — Psalm 23:1\n\n..."
    /// Output: "Luke 3:7-8: Fruits Worthy of Repentance"
    static func parseDevotionalHeading(_ message: String) -> String? {
        let cleaned = message
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
        let paragraphs = cleaned.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let first = paragraphs.first else { return nil }
        if let dashRange = first.range(of: " — ") {
            return String(first[dashRange.upperBound...])
        }
        return first
    }

    /// Pull a short readable snippet from the devotional body, skipping the
    /// title paragraph and truncating at a word boundary.
    static func parseDevotionalBody(_ message: String, maxLength: Int) -> String {
        let cleaned = message
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "> ", with: "")
        let paragraphs = cleaned.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard paragraphs.count > 1 else { return "" }
        let body = paragraphs[1]
        guard body.count > maxLength else { return body }
        let truncated = body.prefix(maxLength)
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "\u{2026}"
        }
        return String(truncated) + "\u{2026}"
    }

    /// Fallback pool used when no cached devotional is available (e.g. brand
    /// new install on first launch). Hand-curated short, well-known,
    /// gain-framed verses. Order is fixed — append, never insert, so
    /// day-of-year picks remain consistent across releases.
    private static let welcomeVersePool: [(text: String, reference: String)] = [
        ("Your word is a lamp for my feet, a light on my path.", "Psalm 119:105"),
        ("Be still, and know that I am God.", "Psalm 46:10"),
        ("The Lord is my shepherd, I lack nothing.", "Psalm 23:1"),
        ("I can do all this through him who gives me strength.", "Philippians 4:13"),
        ("Be strong and courageous. Do not be afraid.", "Joshua 1:9"),
        ("Do not fear, for I am with you.", "Isaiah 41:10"),
        ("In all things God works for the good of those who love him.", "Romans 8:28")
    ]

    static func dailyWelcomeVerse(for date: Date) -> (text: String, reference: String) {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % welcomeVersePool.count
        return welcomeVersePool[index]
    }

    var howToSteps: [String] {
        switch self {
        case .welcome, .dailyReminder, .achievements, .explain:
            return []
        case .watchApp:
            return [
                "Open the Watch app on your iPhone",
                "Scroll to swiftbible",
                "Tap Install"
            ]
        case .widget:
            return [
                "Long-press your Home Screen",
                "Tap the + in the top corner",
                "Search \"swiftbible\" and add the widget"
            ]
        }
    }
}

/// Persistent tracking of which onboarding features the user has already seen.
///
/// Stored as a comma-separated list of raw values in `UserDefaults`. We use a
/// string instead of JSON to keep the format readable and avoid needing a
/// custom `RawRepresentable` wrapper for `Set`.
enum OnboardingPreferences {
    static let seenFeaturesKey = "onboardingSeenFeatures"
    static let hasLaunchedBeforeKey = "onboardingHasLaunchedBefore"

    static func seenFeatures() -> Set<OnboardingFeature> {
        let raw = UserDefaults.standard.string(forKey: seenFeaturesKey) ?? ""
        let tokens = raw.split(separator: ",").map(String.init)
        return Set(tokens.compactMap(OnboardingFeature.init(rawValue:)))
    }

    static func markSeen(_ features: [OnboardingFeature]) {
        var current = seenFeatures()
        current.formUnion(features)
        let raw = current.map(\.rawValue).sorted().joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: seenFeaturesKey)
    }

    /// Clear all seen features — used by the "Show Tour Again" action so the
    /// user can re-watch the full onboarding from the beginning.
    static func resetAll() {
        UserDefaults.standard.removeObject(forKey: seenFeaturesKey)
    }

    /// Wipe every onboarding flag so the next app launch behaves exactly
    /// like a brand-new install. Used by the debug "Reset Onboarding"
    /// button — `resetAll()` only clears the seen-features set, but the
    /// `hasLaunchedBefore` flag also has to be cleared for `pendingFeatures()`
    /// to take the first-launch branch.
    static func resetCompletely() {
        UserDefaults.standard.removeObject(forKey: seenFeaturesKey)
        UserDefaults.standard.removeObject(forKey: hasLaunchedBeforeKey)
    }

    /// Returns the features that should be shown next time onboarding runs.
    ///
    /// - On first launch: every feature (full welcome tour).
    /// - On subsequent launches: only features added since the last time the
    ///   user completed the flow (a "What's New" spotlight).
    @MainActor
    static func pendingFeatures() -> [OnboardingFeature] {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
        let seen = seenFeatures()

        if !hasLaunchedBefore {
            return OnboardingFeature.availableCases
        }

        return OnboardingFeature.availableCases.filter { !seen.contains($0) }
    }

    static func markLaunched() {
        UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
    }
}
