//
//  AnalyticsService.swift
//  swiftbible
//

import Foundation
import PostHog

enum AnalyticsEvent: String {
    // Navigation
    case tabSwitched = "tab_switched"
    case bookOpened = "book_opened"
    case chapterViewed = "chapter_viewed"
    case chapterNavigated = "chapter_navigated"

    // Verse interactions
    case verseActionMenu = "verse_action_menu"
    case verseCopied = "verse_copied"
    case verseBookmarked = "verse_bookmarked"
    case verseHighlighted = "verse_highlighted"
    case verseUnhighlighted = "verse_unhighlighted"
    case verseNoteOpened = "verse_note_opened"
    case verseExplained = "verse_explained"
    case verseShared = "verse_shared"

    // Search
    case searchPerformed = "search_performed"
    case searchResultTapped = "search_result_tapped"

    // Devotional
    case devotionalViewed = "devotional_viewed"
    case devotionalSaved = "devotional_saved"
    case devotionalUnsaved = "devotional_unsaved"
    case devotionalCopied = "devotional_copied"

    // Settings
    case versionChanged = "version_changed"
    case apocryphaToggled = "apocrypha_toggled"
    case enochToggled = "enoch_toggled"
    case jubileesToggled = "jubilees_toggled"
    case testamentsToggled = "testaments_toggled"
    case secondEnochToggled = "second_enoch_toggled"
    case didacheToggled = "didache_toggled"
    case firstClementToggled = "first_clement_toggled"
    case thematicGroupingToggled = "thematic_grouping_toggled"
    case jesusWordsToggled = "jesus_words_toggled"
    case devotionalReminderToggled = "devotional_reminder_toggled"
    case fontChanged = "font_changed"
    case fontSizeChanged = "font_size_changed"
    case summarySourceChanged = "summary_source_changed"

    // Donation funnel
    case donationPromptShown = "donation_prompt_shown"
    case donationStarted = "donation_started"
    case donationPaymentSheetShown = "donation_payment_sheet_shown"
    case donationCompleted = "donation_completed"
    case donationCancelled = "donation_cancelled"
    case donationFailed = "donation_failed"
    case donationPromptDismissed = "donation_prompt_dismissed"
    case donationPromptOptedOut = "donation_prompt_opted_out"

    // Donor perks
    case readingThemeChanged = "reading_theme_changed"
    case appIconChanged = "app_icon_changed"
    case readingStatsViewed = "reading_stats_viewed"

    // Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingFeatureViewed = "onboarding_feature_viewed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingReplayRequested = "onboarding_replay_requested"
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func configure() {
        let apiKey = AppConfig.posthogAPIKey
        guard !apiKey.isEmpty else {
            print("[PostHog] Skipping setup — no API key configured")
            return
        }
        let config = PostHogConfig(apiKey: apiKey, host: "https://us.i.posthog.com")
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = true
        #if DEBUG
        config.debug = true
        #endif
        PostHogSDK.shared.setup(config)
    }

    func capture(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event.rawValue, properties: properties)
    }

    func screen(_ name: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.screen(name, properties: properties)
    }

    func getFeatureFlag(_ key: String) -> String? {
        PostHogSDK.shared.getFeatureFlag(key) as? String
    }
}
