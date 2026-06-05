package biz.am2.swiftbible.ui.onboarding

import biz.am2.swiftbible.data.GeminiNanoExplainer
import java.time.LocalDate
import java.time.temporal.ChronoField

/**
 * Features that are introduced via the onboarding flow.
 *
 * Add a new case when shipping a feature worth spotlighting. Existing users
 * who have already seen older features will be shown only the new ones as a
 * "What's New" sheet; new installs see every case as a full onboarding.
 *
 * Mirrors `OnboardingFeature` in iOS `OnboardingView.swift`. The Android
 * baseline currently includes only the iOS cases that apply to this platform.
 */
enum class OnboardingFeature(val id: String) {
    WELCOME("welcome"),
    DAILY_REMINDER("dailyReminder"),
    ACHIEVEMENTS("achievements"),
    EXPLAIN("explain"),
    ;

    /** Identity-led, action-oriented page titles. */
    val title: String
        get() = when (this) {
            WELCOME -> "Make Scripture part of your day"
            DAILY_REMINDER -> "A gentle nudge, on your schedule"
            ACHIEVEMENTS -> "Celebrate your progress"
            EXPLAIN -> "Ask the text. Go deeper."
        }

    /**
     * Subtitles use Tiny Habits framing ("after X, do Y") for the feature
     * pages so the new behaviour is anchored to an existing routine.
     */
    val subtitle: String
        get() = when (this) {
            WELCOME -> "A quiet space to read, reflect, and return — designed to keep you in the Word."
            DAILY_REMINDER -> "Pick a time that fits your day — morning coffee, evening wind-down — and we'll send a gentle reminder to open today's devotional."
            ACHIEVEMENTS -> "As you read, you'll build streaks and unlock badges for milestones along the way. We celebrate each one with a little banner — switch those off anytime in Settings."
            EXPLAIN -> "Long-press any verse for an AI explanation. Powered by on-device Gemini Nano — your reading stays on your phone."
        }

    /**
     * Whether the case can run on this device. Mirrors iOS
     * `isSupportedOnThisDevice` — `EXPLAIN` is gated on Gemini Nano support
     * (Pixel 8 Pro+, Pixel 9/10 series, Galaxy S24+, other 2024+ flagships);
     * older devices never see the page.
     */
    suspend fun isSupportedOnDevice(): Boolean = when (this) {
        EXPLAIN -> GeminiNanoExplainer.isSupportedOnDevice()
        else -> true
    }

    companion object {
        /** Onboarding cases this device can actually use. */
        suspend fun availableCases(): List<OnboardingFeature> =
            entries.filter { it.isSupportedOnDevice() }

        /**
         * Reciprocity: a small "gift" verse rendered on the welcome page.
         * Hand-curated short, gain-framed verses. Order is fixed — append,
         * never insert, so day-of-year picks remain consistent across releases.
         */
        private val welcomeVersePool: List<Pair<String, String>> = listOf(
            "Your word is a lamp for my feet, a light on my path." to "Psalm 119:105",
            "Be still, and know that I am God." to "Psalm 46:10",
            "The Lord is my shepherd, I lack nothing." to "Psalm 23:1",
            "I can do all this through him who gives me strength." to "Philippians 4:13",
            "Be strong and courageous. Do not be afraid." to "Joshua 1:9",
            "Do not fear, for I am with you." to "Isaiah 41:10",
            "In all things God works for the good of those who love him." to "Romans 8:28",
        )

        fun dailyWelcomeVerse(date: LocalDate = LocalDate.now()): Pair<String, String> {
            val dayOfYear = date.get(ChronoField.DAY_OF_YEAR)
            val index = ((dayOfYear - 1) % welcomeVersePool.size + welcomeVersePool.size) % welcomeVersePool.size
            return welcomeVersePool[index]
        }
    }
}
