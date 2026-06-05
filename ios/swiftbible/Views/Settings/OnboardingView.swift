//
//  OnboardingView.swift
//  swiftbible
//
//  First-launch welcome tour and incremental "What's New" feature spotlight.
//
//  Behavioural design notes (see /gatena-cookbook review):
//  • Endowed Progress Effect — progress bar starts at 1/N already filled.
//  • Goal Gradient — explicit "Step X of N" surfaces proximity to completion.
//  • Identity-Based Motivation — copy speaks to who the user wants to become.
//  • Tiny Habits — Watch/Widget pages anchor to existing daily routines.
//  • Reciprocity — welcome page gives a verse before asking for anything.
//  • Autonomy Bias — Skip button restores user control, prevents reactance.
//  • Peak-End Rule — final button uses an action verb + haptic acknowledgement.
//

import SwiftUI
import AVKit
#if canImport(UIKit)
import UIKit
#endif

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

// MARK: - View

struct OnboardingView: View {
    let features: [OnboardingFeature]
    let source: String
    let onFinish: () -> Void

    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            header
            if showsProgressChrome {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }

            TabView(selection: $currentIndex) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    OnboardingPage(feature: feature)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif

            continueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 4)
        }
        .accessibilityIdentifier("OnboardingView")
        .interactiveDismissDisabled()
        .onAppear {
            AnalyticsService.shared.capture(.onboardingStarted, properties: [
                "source": source,
                "feature_count": features.count,
                "features": features.map(\.rawValue)
            ])
            captureView(of: features.first)
        }
        .onChange(of: currentIndex) { _, newIndex in
            captureView(of: features[safe: newIndex])
        }
    }

    // MARK: - Sub-views (extracted to keep the body type-checker-friendly)

    private var header: some View {
        HStack {
            if showsProgressChrome {
                Text("Step \(currentIndex + 1) of \(features.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Skip", action: skip)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("OnboardingSkipButton")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    /// Hide the "Step X of N" + progress bar when there's only a single
    /// feature to show (e.g. a one-page "What's New" sheet) — "Step 1 of 1"
    /// looks silly and a 100%-full bar adds nothing.
    private var showsProgressChrome: Bool {
        features.count > 1
    }

    /// Endowed Progress: the bar starts at 1/N filled the moment the sheet
    /// opens — the user is "credited" for showing up before doing any work.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * progressFraction)
                    .animation(.easeInOut(duration: 0.35), value: currentIndex)
            }
        }
        .frame(height: 6)
    }

    private var progressFraction: CGFloat {
        guard !features.isEmpty else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(features.count)
    }

    private var continueButton: some View {
        Button(action: advance) {
            Text(buttonLabel)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityIdentifier("OnboardingContinueButton")
    }

    private var buttonLabel: String {
        // Implementation-Intention copy: a verb that names the next action.
        isLastPage ? "Start Reading" : "Continue"
    }

    private var isLastPage: Bool {
        currentIndex >= features.count - 1
    }

    // MARK: - Actions

    private func advance() {
        playHaptic(.light)
        if isLastPage {
            AnalyticsService.shared.capture(.onboardingCompleted, properties: [
                "source": source,
                "feature_count": features.count,
                "features": features.map(\.rawValue)
            ])
            onFinish()
        } else {
            withAnimation { currentIndex += 1 }
        }
    }

    private func skip() {
        playHaptic(.soft)
        AnalyticsService.shared.capture(.onboardingSkipped, properties: [
            "source": source,
            "skipped_at_index": currentIndex,
            "skipped_at_feature": features[safe: currentIndex]?.rawValue ?? "unknown",
            "feature_count": features.count
        ])
        onFinish()
    }

    private func captureView(of feature: OnboardingFeature?) {
        guard let feature else { return }
        AnalyticsService.shared.capture(.onboardingFeatureViewed, properties: [
            "feature": feature.rawValue,
            "source": source
        ])
    }

    private func playHaptic(_ style: HapticStyle) {
        #if os(iOS)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = UIImpactFeedbackGenerator(style: .light)
        case .soft: generator = UIImpactFeedbackGenerator(style: .soft)
        }
        generator.impactOccurred()
        #endif
    }

    private enum HapticStyle { case light, soft }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Page

private struct OnboardingPage: View {
    let feature: OnboardingFeature

    /// Network-fetched welcome snippet. When set, overrides the sync
    /// `feature.welcomeVerse` (which falls back to the pool on cache miss).
    @State private var fetchedSnippet: (text: String, reference: String)?

    /// Toggles the repeating bounce on the `dailyReminder` bell hero.
    @State private var bellBounce = false

    /// Toggles the repeating bounce on the `achievements` trophy hero.
    @State private var trophyBounce = false

    /// Presents `NotificationSettingsView` from the `dailyReminder` page CTA.
    @State private var showingReminderSettings = false

    /// What the welcome card actually renders.
    /// Priority: network fetch → cache → pool fallback.
    private var displayedVerse: (text: String, reference: String)? {
        fetchedSnippet ?? feature.welcomeVerse
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)
            heroImage
            titleBlock
            verseGiftOrSteps
            inlineAction
            Spacer(minLength: 8)
        }
        .task {
            // Only the welcome page needs the live devotional. If cache is
            // already populated, the sync path in `feature.welcomeVerse`
            // already returned the real snippet — no need to re-fetch.
            guard feature == .welcome else { return }
            guard OnboardingFeature.todaysDevotionalSnippet() == nil else { return }
            await fetchTodaysDevotionalAndUpdate()
        }
        .sheet(isPresented: $showingReminderSettings) {
            NavigationStack {
                NotificationSettingsView()
            }
        }
    }

    /// Fetch today's devotional from Supabase, cache it, and swap the
    /// welcome card from the pool fallback to the real content. Silently
    /// no-ops on failure (offline, no devotional yet, etc.) — the pool
    /// fallback that's already on screen remains.
    private func fetchTodaysDevotionalAndUpdate() async {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        do {
            let devotional = try await DevotionalService.shared.fetchDailyDevotional(forDate: dateString)
            CacheService.shared.saveDevotional(devotional, for: Date())
            if let snippet = OnboardingFeature.todaysDevotionalSnippet() {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        fetchedSnippet = snippet
                    }
                }
            }
        } catch {
            print("Onboarding devotional fetch failed: \(error.localizedDescription)")
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        switch feature {
        case .welcome:
            welcomeIcon
        case .dailyReminder:
            dailyReminderBell
        case .achievements:
            achievementsHero
        case .watchApp:
            watchFramedImage
        case .widget:
            widgetFramedImage
        case .explain:
            explainVideo
        }
    }

    /// Gold bell in a soft gradient halo, bouncing on a slow loop to draw
    /// the eye without feeling frantic. Matches the hero in
    /// `NotificationSettingsView` so the visual language is continuous when
    /// the user taps the CTA below.
    @ViewBuilder
    private var dailyReminderBell: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandGold.opacity(0.25), Color.brandGold.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .shadow(color: Color.brandGold.opacity(0.35), radius: 24, y: 10)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.brandGold, .brandGold.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolEffect(.bounce, options: .repeat(.continuous), value: bellBounce)
        }
        .accessibilityHidden(true)
        .onAppear {
            // Flip once so the repeating symbolEffect has a trigger value.
            bellBounce.toggle()
        }
    }

    /// A celebratory "podium" of badge medallions — a raised gold trophy
    /// flanked by a streak flame and a books medal — sitting in the same
    /// gold halo as the banner the user sees when they actually earn a
    /// badge, so the visual language is continuous.
    @ViewBuilder
    private var achievementsHero: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.brandGold.opacity(0.25), Color.brandGold.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 168, height: 168)
                .shadow(color: Color.brandGold.opacity(0.35), radius: 24, y: 10)

            HStack(alignment: .center, spacing: -14) {
                medallion(systemImage: "flame.fill", tint: .brandRed, size: 64)
                    .rotationEffect(.degrees(-8))
                    .offset(y: 22)
                medallion(systemImage: "trophy.fill", tint: .brandGold, size: 94)
                    .offset(y: -16)
                    .symbolEffect(.bounce, options: .repeat(.continuous), value: trophyBounce)
                    .zIndex(1)
                medallion(systemImage: "book.fill", tint: .brandAccent, size: 64)
                    .rotationEffect(.degrees(8))
                    .offset(y: 22)
            }
        }
        .frame(height: 200)
        .accessibilityHidden(true)
        .onAppear {
            // Flip once so the repeating symbolEffect has a trigger value.
            trophyBounce.toggle()
        }
    }

    /// A single circular badge medallion: a glossy two-stop fill, a soft
    /// white rim, a coloured drop shadow, and a white glyph.
    private func medallion(systemImage: String, tint: Color, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint, tint.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 2)
                )
                .shadow(color: tint.opacity(0.45), radius: 10, y: 6)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    /// Supporting card for the achievements page: a Bronze → Diamond tier
    /// strip (shows the climb has depth) plus the "you can turn off the
    /// celebration banners" reassurance the page is really about.
    private var achievementsShelf: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                tierDot(Self.bronze)
                tierConnector
                tierDot(Self.silver)
                tierConnector
                tierDot(.brandGold)
                tierConnector
                tierDot(.brandCyan)
            }
            Text("Climb every track from Bronze to Diamond.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Divider().opacity(0.4)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(Color.brandGold)
                Text("Prefer calm? Turn the celebration banners off anytime in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.brandGold.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tierDot(_ color: Color) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 18, height: 18)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
            .shadow(color: color.opacity(0.4), radius: 3, y: 1)
    }

    private var tierConnector: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 16, height: 2)
    }

    /// Metallic tier accents that don't exist in the brand palette.
    private static let bronze = Color(red: 0.80, green: 0.50, blue: 0.20)
    private static let silver = Color(red: 0.74, green: 0.76, blue: 0.80)

    /// Looping muted preview of the Explain flow (tap → stream → follow-up).
    /// Falls back to a stylized sparkles hero if the bundled mp4 is missing
    /// (e.g. during early development before the clip has been recorded).
    @ViewBuilder
    private var explainVideo: some View {
        if let url = Bundle.main.url(forResource: "OnboardingExplain", withExtension: "mp4") {
            LoopingVideoPlayer(url: url)
                .aspectRatio(9.0 / 19.5, contentMode: .fit)
                .frame(maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 20, y: 12)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.brandAccent.opacity(0.22), Color.brandCyan.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxHeight: 260)
                Image(systemName: "sparkles")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Color.brandAccent)
                    .symbolEffect(.pulse, options: .repeat(.continuous))
            }
            .accessibilityHidden(true)
        }
    }

    /// The welcome page shows the brand app icon with a modest rounded square
    /// — Halo Effect via the strongest brand asset on first impression.
    @ViewBuilder
    private var welcomeIcon: some View {
        if let imageName = feature.imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 22, y: 10)
        }
    }

    /// Wraps the watch screen capture in a heavy continuous-corner frame
    /// with a dark bezel so it reads as "this is what you'll see ON the
    /// watch" rather than "this is a flat screenshot."
    @ViewBuilder
    private var watchFramedImage: some View {
        if let imageName = feature.imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 52, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 52, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.92), lineWidth: 6)
                )
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        }
    }

    /// Renders the widget screenshot with the standard iOS widget corner
    /// radius and a soft drop shadow so it looks like it's floating on a
    /// home screen, not pasted into a flat sheet.
    @ViewBuilder
    private var widgetFramedImage: some View {
        if let imageName = feature.imageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.20), radius: 18, y: 10)
                .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text(feature.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(feature.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var verseGiftOrSteps: some View {
        if let verse = displayedVerse {
            VStack(spacing: 12) {
                verseCard(text: verse.text, reference: verse.reference)
                openSourceBadge
            }
        } else if feature == .achievements {
            achievementsShelf
        } else if !feature.howToSteps.isEmpty {
            stepsCard
        }
    }

    /// Reciprocity: a small gift before the user is asked to do anything.
    private func verseCard(text: String, reference: String) -> some View {
        VStack(spacing: 8) {
            Text("\u{201C}\(text)\u{201D}")
                .font(.body.italic())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(reference)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Authentic differentiator instead of fabricated user counts.
    /// Leverages Noble Edge Effect (genuine values claim) and Self-Signalling
    /// (people who choose this app want to identify as the kind of person
    /// who values free, open, ad-free software).
    private var openSourceBadge: some View {
        HStack(spacing: 6) {
            Label("Free", systemImage: "gift.fill")
            Text("\u{2022}")
            Label("Open Source", systemImage: "chevron.left.forwardslash.chevron.right")
            Text("\u{2022}")
            Label("No Ads", systemImage: "hand.raised.fill")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
    }

    /// Per-page secondary action. Currently only the `dailyReminder` page
    /// surfaces one: a "Set Reminder Time" button that opens
    /// `NotificationSettingsView` in a sheet so the user can commit to a
    /// time without leaving the onboarding flow.
    @ViewBuilder
    private var inlineAction: some View {
        if feature == .dailyReminder {
            Button {
                showingReminderSettings = true
            } label: {
                Label("Set Reminder Time", systemImage: "clock.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.brandGold.opacity(0.18))
                    .foregroundStyle(Color.brandGold)
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier("OnboardingDailyReminderSetTimeButton")
        }
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to add it")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(Array(feature.howToSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1).")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(step)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Looping video player

/// A compact AVPlayerLayer-backed view that loops a muted local video.
/// Used for the Explain feature preview. AVKit's `VideoPlayer` ships full
/// playback chrome we don't want for a decorative loop, so we drop to
/// `AVPlayerLayer` and handle looping via `AVPlayerLooper`.
private struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingVideoUIView {
        let view = LoopingVideoUIView()
        view.configure(with: url)
        return view
    }

    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) { }
}

private final class LoopingVideoUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var looper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?

    func configure(with url: URL) {
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.actionAtItemEnd = .advance
        looper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player

        if let layer = layer as? AVPlayerLayer {
            layer.player = player
            layer.videoGravity = .resizeAspectFill
        }

        player.play()
    }
}

// MARK: - Host modifier

/// A single value that bundles everything needed to present onboarding.
/// Using one identifiable item (instead of three separate `@Binding`s)
/// avoids a SwiftUI race where `isPresented = true` would commit before
/// `features = allCases` propagated to the sheet's content closure — which
/// is what was rendering the welcome tour as an empty page after the user
/// had already completed it once.
struct OnboardingPresentation: Identifiable, Equatable {
    let id = UUID()
    let features: [OnboardingFeature]
    let source: String
}

/// Hosts the onboarding sheet plus the replay-from-Settings notification
/// listener, packaged as a single modifier so `ContentView`'s body doesn't
/// accumulate more chained modifiers (which has historically blown past
/// the Swift type-checker's complexity budget).
struct OnboardingHost: ViewModifier {
    @Binding var presentation: OnboardingPresentation?

    func body(content: Content) -> some View {
        content
            .sheet(item: $presentation) { item in
                OnboardingView(features: item.features, source: item.source) {
                    OnboardingPreferences.markSeen(item.features)
                    OnboardingPreferences.markLaunched()
                    presentation = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .onboardingReplayRequested)) { _ in
                AnalyticsService.shared.capture(.onboardingReplayRequested)
                // "Show Welcome Tour" should re-show the FULL tour every
                // time, regardless of which features the user has seen
                // before. Item-based presentation guarantees the new
                // features array is what the sheet actually receives.
                presentation = OnboardingPresentation(
                    features: OnboardingFeature.availableCases,
                    source: "settings_replay"
                )
            }
    }
}

#Preview("Full Tour") {
    OnboardingView(features: OnboardingFeature.availableCases, source: "preview_first_launch") { }
}

#Preview("What's New") {
    OnboardingView(features: [.watchApp, .widget], source: "preview_whats_new") { }
}

#Preview("Achievements") {
    OnboardingView(features: [.achievements], source: "preview_whats_new") { }
}
