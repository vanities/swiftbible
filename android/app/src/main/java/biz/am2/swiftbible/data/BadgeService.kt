package biz.am2.swiftbible.data

import android.content.Context
import biz.am2.swiftbible.ui.ToastCoordinator
import java.util.Calendar
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Android mirror of iOS BadgeService. Evaluates every badge condition
 * against the current state and inserts new EarnedBadge rows for any that
 * newly qualify, then enqueues a toast via [ToastCoordinator] so it
 * surfaces immediately wherever the user is.
 */
class BadgeService(
    private val context: Context,
    private val stats: ReadingStatsRepository,
    private val sessionDao: ReadingSessionDao,
    private val earnedDao: EarnedBadgeDao,
) {
    /**
     * Walks every BadgeDefinition, checks the condition, and emits newly
     * earned badges. Safe to call from any read or scene-active hook;
     * earned IDs are deduped via the [EarnedBadge.badgeId] primary key.
     */
    suspend fun checkBadges(now: Long = System.currentTimeMillis()): List<BadgeDefinition> {
        val earnedIds = earnedDao.earnedIds().toMutableSet()
        val newlyEarned = mutableListOf<BadgeDefinition>()
        for (def in BadgeRegistry.all) {
            if (def.id in earnedIds) continue
            if (!evaluate(def, now)) continue
            earnedDao.insert(EarnedBadge(badgeId = def.id, earnedAt = now))
            earnedIds += def.id
            newlyEarned += def
            ToastCoordinator.enqueue(def)
            Analytics.capture(
                Analytics.Event.BadgeEarned,
                mapOf("badge_id" to def.id, "category" to def.category.name.lowercase(), "name" to def.name),
            )
        }
        return newlyEarned
    }

    fun checkBadgesAsync(scope: CoroutineScope) {
        scope.launch(Dispatchers.IO) { checkBadges() }
    }

    suspend fun currentTier(track: BadgeTrack): BadgeTier? {
        val earned = earnedDao.earnedIds()
        return BadgeRegistry.tiers
            .filter { it.track == track && it.id in earned }
            .mapNotNull { it.tier }
            .maxByOrNull { it.order }
    }

    // MARK: - Evaluation

    private suspend fun evaluate(def: BadgeDefinition, now: Long): Boolean = when (def.category) {
        BadgeCategory.TIER -> evaluateTier(def)
        BadgeCategory.COLLECTIBLE -> evaluateCollectible(def)
        BadgeCategory.HIDDEN -> evaluateHidden(def, now)
    }

    private suspend fun evaluateTier(def: BadgeDefinition): Boolean {
        val track = def.track ?: return false
        val threshold = def.threshold ?: return false
        return when (track) {
            BadgeTrack.STREAK -> stats.currentStreakWithFreeze().streak >= threshold
            BadgeTrack.CHAPTERS -> totalChapters() >= threshold
            BadgeTrack.BOOKS -> completedBookCount() >= threshold
            BadgeTrack.DEVOTIONALS -> stats.devotionalReadCount() >= threshold
        }
    }

    private suspend fun evaluateCollectible(def: BadgeDefinition): Boolean = when (def.id) {
        "collect.gospels" -> allComplete(listOf("Matthew", "Mark", "Luke", "John"))
        "collect.pentateuch" -> allComplete(listOf("Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"))
        "collect.major.prophets" -> allComplete(listOf("Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel"))
        "collect.minor.prophets" -> allComplete(
            listOf(
                "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah",
                "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi",
            ),
        )
        "collect.pauline" -> allComplete(
            listOf(
                "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
                "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
                "1 Timothy", "2 Timothy", "Titus", "Philemon",
            ),
        )
        "collect.wisdom" -> allComplete(listOf("Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon"))
        "collect.enoch" -> CanonicalBibleBooks.enochSections.all { stats.chaptersReadInBook(it).isNotEmpty() }
        "collect.apocrypha" -> CanonicalBibleBooks.apocryphaNames.all { stats.chaptersReadInBook(it).isNotEmpty() }
        "collect.whole.counsel" -> completedBookCount() >= 66
        else -> false
    }

    private suspend fun evaluateHidden(def: BadgeDefinition, now: Long): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = now }
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        return when (def.id) {
            "hidden.night.owl" -> hour in 0..2 && chaptersReadOn(now) > 0
            "hidden.early.bird" -> hour in 4..5 && chaptersReadOn(now) > 0
            "hidden.marathon" -> chaptersReadOn(now) >= 10
            "hidden.pentecost" -> LiturgicalCalendar.isPentecost(now) && readChapterToday("Acts", 2)
            "hidden.resurrection.sunday" -> LiturgicalCalendar.isEaster(now) && chaptersReadOn(now) > 0
            "hidden.christmas.story" -> LiturgicalCalendar.isChristmas(now) && readChapterToday("Luke", 2)
            "hidden.all.voices" -> {
                val tracks = DevotionalHistory.tracksInLast(context, days = 7)
                listOf("empathy", "technical", "narrative", "practical").all { it in tracks }
            }
            "hidden.series.completionist" -> {
                val progress = DevotionalHistory.seriesProgress(context)
                progress.values.any { it.containsAll(setOf(1, 2, 3, 4)) }
            }
            "hidden.phoenix" -> {
                val info = stats.currentStreakWithFreeze()
                info.freezeActive && info.streak > 0
            }
            "hidden.late.wisdom" -> hour >= 22 && readChapterToday("Proverbs", chapter = null)
            else -> false
        }
    }

    // MARK: - Aggregates

    private suspend fun totalChapters(): Int {
        val rows = sessionDao.allBookSessions()
        return rows.map { "${it.bookName}-${it.chapterNumber}" }.toSet().size
    }

    private suspend fun completedBookCount(): Int =
        CanonicalBibleBooks.all.count { entry ->
            stats.chaptersReadInBook(entry.name).size >= entry.totalChapters
        }

    private suspend fun allComplete(books: List<String>): Boolean {
        for (book in books) {
            val read = stats.chaptersReadInBook(book).size
            val total = CanonicalBibleBooks.all.firstOrNull { it.name == book }?.totalChapters
            if (total == null) {
                // Book not in canonical chapter-count table (apocrypha/enoch).
                // Fall back to "at least one chapter read" as a completion proxy.
                if (read == 0) return false
            } else if (read < total) {
                return false
            }
        }
        return true
    }

    private suspend fun chaptersReadOn(epochMs: Long): Int {
        val day = ReadingStatsRepository.startOfDay(epochMs)
        val sessions = sessionDao.since(day).filter {
            it.dayEpoch == day && it.bookName != ReadingStatsRepository.DEVOTIONAL_BOOK
        }
        return sessions.map { "${it.bookName}-${it.chapterNumber}" }.toSet().size
    }

    private suspend fun readChapterToday(book: String, chapter: Int?): Boolean {
        val day = ReadingStatsRepository.startOfDay(System.currentTimeMillis())
        val sessions = sessionDao.since(day).filter { it.dayEpoch == day && it.bookName == book }
        return if (chapter == null) sessions.isNotEmpty()
        else sessions.any { it.chapterNumber == chapter }
    }
}
