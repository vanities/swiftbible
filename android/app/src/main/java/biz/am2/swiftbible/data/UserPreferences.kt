package biz.am2.swiftbible.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import biz.am2.swiftbible.model.Version
import biz.am2.swiftbible.ui.theme.ReadingFont
import biz.am2.swiftbible.ui.theme.ReadingTheme
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "user_prefs")

class UserPreferences(private val context: Context) {

    private object Keys {
        val VERSION = stringPreferencesKey("version")
        val SHOW_APOCRYPHA = booleanPreferencesKey("show_apocrypha")
        val SHOW_ENOCH = booleanPreferencesKey("show_enoch")
        val SHOW_JUBILEES = booleanPreferencesKey("show_jubilees")
        val SHOW_TESTAMENTS = booleanPreferencesKey("show_testaments")
        val SHOW_2ENOCH = booleanPreferencesKey("show_2enoch")
        val SHOW_DIDACHE = booleanPreferencesKey("show_didache")
        val SHOW_1CLEMENT = booleanPreferencesKey("show_1clement")
        val SHOW_THEMATIC = booleanPreferencesKey("show_thematic")
        val JESUS_RED = booleanPreferencesKey("jesus_red")
        val FONT_SIZE = intPreferencesKey("font_size")
        val FONT_FAMILY = stringPreferencesKey("font_family")
        val THEME = stringPreferencesKey("theme")
        val ONBOARDED = booleanPreferencesKey("onboarded")
        val SHOW_SUMMARIES = booleanPreferencesKey("show_summaries")
        val HIDE_BARS = booleanPreferencesKey("hide_bars")
        val LAST_BOOK = stringPreferencesKey("last_book")
        val LAST_CHAPTER = intPreferencesKey("last_chapter")
        val REMINDER_ENABLED = booleanPreferencesKey("reminder_enabled")
        val REMINDER_HOUR = intPreferencesKey("reminder_hour")
        val REMINDER_MINUTE = intPreferencesKey("reminder_minute")
        val HAPPY_MOMENT_COUNT = intPreferencesKey("happy_moment_count")
        val DONATION_OPT_OUT = booleanPreferencesKey("donation_opt_out")
        val LAST_REVIEW_PROMPTED_AT = intPreferencesKey("last_review_prompted_at")
        val FORCE_SHOW_EVENTS = booleanPreferencesKey("force_show_events")
        val SEEN_ONBOARDING_FEATURES = stringPreferencesKey("onboarding_seen_features")
        val SUMMARY_SOURCE = stringPreferencesKey("summary_source")
        val CUSTOM_ACCENT_HEX = stringPreferencesKey("custom_accent_hex")
    }

    data class Snapshot(
        val version: Version = Version.KJV,
        val showApocrypha: Boolean = false,
        val showEnoch: Boolean = false,
        val showJubilees: Boolean = false,
        val showTestaments: Boolean = false,
        val show2Enoch: Boolean = false,
        val showDidache: Boolean = false,
        val show1Clement: Boolean = false,
        val showThematic: Boolean = false,
        val jesusRed: Boolean = true,
        val fontSize: Int = 18,
        val fontFamily: ReadingFont = ReadingFont.LORA,
        val theme: ReadingTheme = ReadingTheme.SYSTEM,
        val onboarded: Boolean = false,
        val showSummaries: Boolean = true,
        val hideBars: Boolean = false,
        val lastBook: String? = null,
        val lastChapter: Int = 1,
        val reminderEnabled: Boolean = false,
        val reminderHour: Int = 21,
        val reminderMinute: Int = 0,
        val happyMomentCount: Int = 0,
        val donationOptOut: Boolean = false,
        val lastReviewPromptedAt: Int = 0,
        val forceShowEvents: Boolean = false,
        val seenOnboardingFeatures: Set<String> = emptySet(),
        val summarySource: SummarySource = SummarySource.Default,
        val customAccentHex: String = "",
    )

    val snapshot: Flow<Snapshot> = context.dataStore.data.map { p ->
        Snapshot(
            version = Version.fromShortName(p[Keys.VERSION] ?: Version.KJV.shortName),
            showApocrypha = p[Keys.SHOW_APOCRYPHA] ?: false,
            showEnoch = p[Keys.SHOW_ENOCH] ?: false,
            showJubilees = p[Keys.SHOW_JUBILEES] ?: false,
            showTestaments = p[Keys.SHOW_TESTAMENTS] ?: false,
            show2Enoch = p[Keys.SHOW_2ENOCH] ?: false,
            showDidache = p[Keys.SHOW_DIDACHE] ?: false,
            show1Clement = p[Keys.SHOW_1CLEMENT] ?: false,
            showThematic = p[Keys.SHOW_THEMATIC] ?: false,
            jesusRed = p[Keys.JESUS_RED] ?: true,
            fontSize = p[Keys.FONT_SIZE] ?: 18,
            fontFamily = ReadingFont.fromName(p[Keys.FONT_FAMILY] ?: ReadingFont.LORA.name),
            theme = ReadingTheme.fromName(p[Keys.THEME] ?: ReadingTheme.SYSTEM.name),
            onboarded = p[Keys.ONBOARDED] ?: false,
            showSummaries = p[Keys.SHOW_SUMMARIES] ?: true,
            hideBars = p[Keys.HIDE_BARS] ?: false,
            lastBook = p[Keys.LAST_BOOK],
            lastChapter = p[Keys.LAST_CHAPTER] ?: 1,
            reminderEnabled = p[Keys.REMINDER_ENABLED] ?: false,
            reminderHour = p[Keys.REMINDER_HOUR] ?: 21,
            reminderMinute = p[Keys.REMINDER_MINUTE] ?: 0,
            happyMomentCount = p[Keys.HAPPY_MOMENT_COUNT] ?: 0,
            donationOptOut = p[Keys.DONATION_OPT_OUT] ?: false,
            lastReviewPromptedAt = p[Keys.LAST_REVIEW_PROMPTED_AT] ?: 0,
            forceShowEvents = p[Keys.FORCE_SHOW_EVENTS] ?: false,
            seenOnboardingFeatures = (p[Keys.SEEN_ONBOARDING_FEATURES] ?: "")
                .split(',')
                .filter { it.isNotBlank() }
                .toSet(),
            summarySource = SummarySource.fromId(p[Keys.SUMMARY_SOURCE]),
            customAccentHex = p[Keys.CUSTOM_ACCENT_HEX] ?: "",
        )
    }

    suspend fun setVersion(v: Version) = update { it[Keys.VERSION] = v.shortName }
    suspend fun setShowApocrypha(b: Boolean) = update { it[Keys.SHOW_APOCRYPHA] = b }
    suspend fun setShowEnoch(b: Boolean) = update { it[Keys.SHOW_ENOCH] = b }
    suspend fun setShowJubilees(b: Boolean) = update { it[Keys.SHOW_JUBILEES] = b }
    suspend fun setShowTestaments(b: Boolean) = update { it[Keys.SHOW_TESTAMENTS] = b }
    suspend fun setShow2Enoch(b: Boolean) = update { it[Keys.SHOW_2ENOCH] = b }
    suspend fun setShowDidache(b: Boolean) = update { it[Keys.SHOW_DIDACHE] = b }
    suspend fun setShow1Clement(b: Boolean) = update { it[Keys.SHOW_1CLEMENT] = b }
    suspend fun setShowThematic(b: Boolean) = update { it[Keys.SHOW_THEMATIC] = b }
    suspend fun setJesusRed(b: Boolean) = update { it[Keys.JESUS_RED] = b }
    suspend fun setFontSize(n: Int) = update { it[Keys.FONT_SIZE] = n }
    suspend fun setFontFamily(f: ReadingFont) = update { it[Keys.FONT_FAMILY] = f.name }
    suspend fun setTheme(t: ReadingTheme) = update { it[Keys.THEME] = t.name }
    suspend fun setOnboarded(b: Boolean) = update { it[Keys.ONBOARDED] = b }
    suspend fun setShowSummaries(b: Boolean) = update { it[Keys.SHOW_SUMMARIES] = b }
    suspend fun setHideBars(b: Boolean) = update { it[Keys.HIDE_BARS] = b }
    suspend fun setLast(book: String, chapter: Int) = update {
        it[Keys.LAST_BOOK] = book
        it[Keys.LAST_CHAPTER] = chapter
    }
    suspend fun setReminderEnabled(b: Boolean) = update { it[Keys.REMINDER_ENABLED] = b }
    suspend fun setReminderTime(hour: Int, minute: Int) = update {
        it[Keys.REMINDER_HOUR] = hour
        it[Keys.REMINDER_MINUTE] = minute
    }

    suspend fun markOnboardingFeaturesSeen(ids: Collection<String>) = context.dataStore.edit { p ->
        val current = (p[Keys.SEEN_ONBOARDING_FEATURES] ?: "")
            .split(',')
            .filter { it.isNotBlank() }
            .toMutableSet()
        current.addAll(ids)
        p[Keys.SEEN_ONBOARDING_FEATURES] = current.sorted().joinToString(",")
    }

    suspend fun resetOnboarding() = context.dataStore.edit { p ->
        p.remove(Keys.SEEN_ONBOARDING_FEATURES)
        p[Keys.ONBOARDED] = false
    }

    suspend fun setSummarySource(source: SummarySource) = update { it[Keys.SUMMARY_SOURCE] = source.id }
    suspend fun setCustomAccentHex(hex: String) = update {
        if (hex.isBlank()) it.remove(Keys.CUSTOM_ACCENT_HEX) else it[Keys.CUSTOM_ACCENT_HEX] = hex
    }

    suspend fun setDonationOptOut(b: Boolean) = update { it[Keys.DONATION_OPT_OUT] = b }
    suspend fun setLastReviewPromptedAt(count: Int) = update { it[Keys.LAST_REVIEW_PROMPTED_AT] = count }
    suspend fun setForceShowEvents(b: Boolean) = update { it[Keys.FORCE_SHOW_EVENTS] = b }

    suspend fun incrementHappyMomentCount(): Int {
        var next = 0
        context.dataStore.edit { p ->
            val curr = p[Keys.HAPPY_MOMENT_COUNT] ?: 0
            next = curr + 1
            p[Keys.HAPPY_MOMENT_COUNT] = next
        }
        return next
    }

    private suspend fun update(block: (androidx.datastore.preferences.core.MutablePreferences) -> Unit) {
        context.dataStore.edit(block)
    }
}
