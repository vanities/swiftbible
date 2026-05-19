package biz.am2.swiftbible.data

import android.content.Context
import com.posthog.PostHog
import com.posthog.PostHogConfig
import com.posthog.android.PostHogAndroid
import com.posthog.android.PostHogAndroidConfig

object Analytics {
    private var initialized = false

    fun init(context: Context) {
        if (initialized) return
        val cfg = PostHogAndroidConfig(
            apiKey = SupabaseConfig.POSTHOG_API_KEY,
            host = SupabaseConfig.POSTHOG_HOST,
        ).apply {
            captureApplicationLifecycleEvents = true
            captureDeepLinks = true
            captureScreenViews = false
            sessionReplay = false
        }
        PostHogAndroid.setup(context.applicationContext, cfg)
        initialized = true
    }

    fun capture(event: Event, properties: Map<String, Any> = emptyMap()) {
        if (!initialized) return
        PostHog.capture(event = event.id, properties = properties.takeIf { it.isNotEmpty() })
    }

    fun screen(name: String) {
        if (!initialized) return
        PostHog.screen(name)
    }

    /** Mirrors iOS [`AnalyticsEvent`] in `swiftbible/Services/AnalyticsService.swift`. Keep in sync. */
    enum class Event(val id: String) {
        // Navigation
        TabSwitched("tab_switched"),
        BookOpened("book_opened"),
        ChapterViewed("chapter_viewed"),
        ChapterNavigated("chapter_navigated"),

        // Verse interactions
        VerseActionMenu("verse_action_menu"),
        VerseCopied("verse_copied"),
        VerseBookmarked("verse_bookmarked"),
        VerseHighlighted("verse_highlighted"),
        VerseUnhighlighted("verse_unhighlighted"),
        VerseNoteOpened("verse_note_opened"),
        VerseExplained("verse_explained"),
        VerseShared("verse_shared"),

        // Search
        SearchPerformed("search_performed"),
        SearchResultTapped("search_result_tapped"),

        // Devotional
        DevotionalViewed("devotional_viewed"),
        DevotionalSaved("devotional_saved"),
        DevotionalUnsaved("devotional_unsaved"),
        DevotionalCopied("devotional_copied"),

        // Settings
        VersionChanged("version_changed"),
        ApocryphaToggled("apocrypha_toggled"),
        EnochToggled("enoch_toggled"),
        JubileesToggled("jubilees_toggled"),
        TestamentsToggled("testaments_toggled"),
        SecondEnochToggled("second_enoch_toggled"),
        DidacheToggled("didache_toggled"),
        FirstClementToggled("first_clement_toggled"),
        ThematicGroupingToggled("thematic_grouping_toggled"),
        JesusWordsToggled("jesus_words_toggled"),
        DevotionalReminderToggled("devotional_reminder_toggled"),
        FontChanged("font_changed"),
        FontSizeChanged("font_size_changed"),
        SummarySourceChanged("summary_source_changed"),

        // Donation funnel
        DonationPromptShown("donation_prompt_shown"),
        DonationStarted("donation_started"),
        DonationPaymentSheetShown("donation_payment_sheet_shown"),
        DonationCompleted("donation_completed"),
        DonationCancelled("donation_cancelled"),
        DonationFailed("donation_failed"),
        DonationPromptDismissed("donation_prompt_dismissed"),
        DonationPromptOptedOut("donation_prompt_opted_out"),

        // Donor perks
        ReadingThemeChanged("reading_theme_changed"),
        ReadingStatsViewed("reading_stats_viewed"),

        // Progress / gamification
        ProgressViewed("progress_viewed"),
        BadgeEarned("badge_earned"),
        BadgeGalleryViewed("badge_gallery_viewed"),

        // Onboarding
        OnboardingStarted("onboarding_started"),
        OnboardingFeatureViewed("onboarding_feature_viewed"),
        OnboardingCompleted("onboarding_completed"),
        OnboardingSkipped("onboarding_skipped"),
        OnboardingReplayRequested("onboarding_replay_requested"),
    }
}
