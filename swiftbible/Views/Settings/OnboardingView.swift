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
    case watchApp
    case widget

    var id: String { rawValue }

    /// Identity-led, action-oriented page titles.
    /// (Identity-Based Motivation — "I am someone who reads scripture daily.")
    var title: String {
        switch self {
        case .welcome: return "Make Scripture part of your day"
        case .watchApp: return "Scripture on your wrist"
        case .widget: return "Today's verse, every unlock"
        }
    }

    /// Subtitles use Tiny Habits framing ("after X, do Y") for the feature
    /// pages so the new behaviour is anchored to an existing routine.
    var subtitle: String {
        switch self {
        case .welcome:
            return "A quiet space to read, reflect, and return — designed to keep you in the Word."
        case .watchApp:
            return "After you check the time, glance at today's devotional. A tiny moment, every day."
        case .widget:
            return "Every time you unlock your phone, today's reading is waiting on your Home Screen."
        }
    }

    var imageName: String? {
        switch self {
        case .welcome: return "Icon-Classic-Preview" // Halo Effect — strong brand impression
        case .watchApp: return "OnboardingWatch"
        case .widget: return "OnboardingWidget"
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
        case .welcome:
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
    static func pendingFeatures() -> [OnboardingFeature] {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
        let seen = seenFeatures()

        if !hasLaunchedBefore {
            return OnboardingFeature.allCases
        }

        return OnboardingFeature.allCases.filter { !seen.contains($0) }
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
            let devotional: DailyDevotional = try await SupabaseService.shared.client
                .from("Daily Devotional")
                .select()
                .eq("for_date", value: dateString)
                .single()
                .execute()
                .value
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
        case .watchApp:
            watchFramedImage
        case .widget:
            widgetFramedImage
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
                    features: OnboardingFeature.allCases,
                    source: "settings_replay"
                )
            }
    }
}

#Preview("Full Tour") {
    OnboardingView(features: OnboardingFeature.allCases, source: "preview_first_launch") { }
}

#Preview("What's New") {
    OnboardingView(features: [.watchApp, .widget], source: "preview_whats_new") { }
}
