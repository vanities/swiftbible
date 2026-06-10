//
//  OnboardingHost.swift
//  swiftbible
//

import SwiftUI

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
