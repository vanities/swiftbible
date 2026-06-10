//
//  OnboardingPage.swift
//  swiftbible
//
//  A single page of the onboarding tour: hero artwork, title block, and the
//  per-feature supporting card (verse gift, achievement shelf, how-to steps).
//

import SwiftUI
import AVKit
import UIKit

struct OnboardingPage: View {
    let feature: OnboardingFeature

    /// Network-fetched welcome snippet. When set, overrides the sync
    /// `feature.welcomeVerse` (which falls back to the pool on cache miss).
    @State private var fetchedSnippet: (text: String, reference: String)?

    /// Toggles the repeating bounce on the `dailyReminder` bell hero.
    @State private var bellBounce = false

    /// Toggles the repeating bounce on the `achievements` trophy hero.
    @State private var trophyBounce = false

    /// Live binding to the achievement-celebration toast preference, so the
    /// onboarding page offers the same switch as Settings ▸ Notifications
    /// instead of only pointing at it.
    @AppStorage(ToastService.achievementToastsKey) private var showAchievementToasts = true

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

            Toggle(isOn: $showAchievementToasts) {
                HStack(spacing: 8) {
                    Image(systemName: showAchievementToasts ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundStyle(Color.brandGold)
                    Text("Celebration banners")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .tint(Color.brandAccent)

            Text("Your badges are recorded either way — change this anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
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
