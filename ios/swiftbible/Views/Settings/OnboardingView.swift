//
//  OnboardingView.swift
//  swiftbible
//
//  First-launch welcome tour and incremental "What's New" feature spotlight.
//  The feature catalog lives in OnboardingFeature.swift, the per-feature page
//  in OnboardingPage.swift, and the presenting modifier in OnboardingHost.swift.
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

#Preview("Full Tour") {
    OnboardingView(features: OnboardingFeature.availableCases, source: "preview_first_launch") { }
}

#Preview("What's New") {
    OnboardingView(features: [.watchApp, .widget], source: "preview_whats_new") { }
}

#Preview("Achievements") {
    OnboardingView(features: [.achievements], source: "preview_whats_new") { }
}
