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
            captureScreenViews = false  // we'll fire our own
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

    enum class Event(val id: String) {
        TabSwitched("tab_switched"),
        BookOpened("book_opened"),
        ChapterViewed("chapter_viewed"),
        ChapterNavigated("chapter_navigated"),

        VerseActionMenu("verse_action_menu"),
        VerseCopied("verse_copied"),
        VerseBookmarked("verse_bookmarked"),
        VerseHighlighted("verse_highlighted"),
        VerseUnhighlighted("verse_unhighlighted"),
        VerseNoteOpened("verse_note_opened"),

        SearchPerformed("search_performed"),
        SearchResultTapped("search_result_tapped"),

        DevotionalViewed("devotional_viewed"),
        DevotionalCopied("devotional_copied"),

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
        FontChanged("font_changed"),
        FontSizeChanged("font_size_changed"),
        ReadingThemeChanged("reading_theme_changed"),
    }
}
