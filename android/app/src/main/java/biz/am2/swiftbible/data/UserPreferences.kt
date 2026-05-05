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
        val LAST_BOOK = stringPreferencesKey("last_book")
        val LAST_CHAPTER = intPreferencesKey("last_chapter")
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
        val lastBook: String? = null,
        val lastChapter: Int = 1,
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
            lastBook = p[Keys.LAST_BOOK],
            lastChapter = p[Keys.LAST_CHAPTER] ?: 1,
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
    suspend fun setLast(book: String, chapter: Int) = update {
        it[Keys.LAST_BOOK] = book
        it[Keys.LAST_CHAPTER] = chapter
    }

    private suspend fun update(block: (androidx.datastore.preferences.core.MutablePreferences) -> Unit) {
        context.dataStore.edit(block)
    }
}
