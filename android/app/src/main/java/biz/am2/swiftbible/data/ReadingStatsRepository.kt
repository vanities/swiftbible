package biz.am2.swiftbible.data

import java.util.Calendar
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * Android mirror of iOS ReadingStatsService.
 *
 * Stores a [ReadingSession] row whenever the user spends time on a
 * chapter (or opens today's devotional). Powers the streak / heatmap /
 * book-completion queries used by the Progress screen and the badge
 * evaluator.
 *
 * Devotional opens use the sentinel `bookName == DEVOTIONAL_BOOK` so they
 * count toward streak/heatmap without inflating chapter-read totals.
 */
class ReadingStatsRepository(private val dao: ReadingSessionDao) {

    suspend fun recordChapterRead(book: String, chapter: Int, version: String) {
        val now = System.currentTimeMillis()
        val day = startOfDay(now)
        if (dao.forBookChapterOnDay(book, chapter, day) != null) return
        dao.insert(
            ReadingSession(
                bookName = book,
                chapterNumber = chapter,
                version = version,
                startedAt = now,
                durationMs = 0,
                dayEpoch = day,
            ),
        )
    }

    suspend fun logDevotionalRead() {
        val now = System.currentTimeMillis()
        val day = startOfDay(now)
        if (dao.forBookChapterOnDay(DEVOTIONAL_BOOK, 0, day) != null) return
        dao.insert(
            ReadingSession(
                bookName = DEVOTIONAL_BOOK,
                chapterNumber = 0,
                version = DEVOTIONAL_VERSION,
                startedAt = now,
                durationMs = 0,
                dayEpoch = day,
            ),
        )
    }

    /** Distinct chapter numbers read in a given book. */
    suspend fun chaptersReadInBook(book: String): Set<Int> =
        dao.forBook(book).map { it.chapterNumber }.toSet()

    /** Marks today's session for this chapter as having reached the last verse. */
    suspend fun markReachedEnd(book: String, chapter: Int, version: String) {
        recordChapterRead(book, chapter, version)
        val s = dao.forBookChapterOnDay(book, chapter, startOfDay(System.currentTimeMillis())) ?: return
        if (!s.reachedEnd) dao.update(s.copy(reachedEnd = true))
    }

    /** Adds foreground dwell time to today's session for this chapter. */
    suspend fun addReadingTime(book: String, chapter: Int, version: String, ms: Long) {
        if (ms <= 0L) return
        recordChapterRead(book, chapter, version)
        val s = dao.forBookChapterOnDay(book, chapter, startOfDay(System.currentTimeMillis())) ?: return
        dao.update(s.copy(durationMs = s.durationMs + ms))
    }

    /** Reactive set of chapters considered "read": reached the last verse AND >=30s dwell. */
    fun readChapterNumbersFlow(book: String): Flow<Set<Int>> =
        dao.readChaptersFlow(book, READ_THRESHOLD_MS).map { it.toSet() }

    /** Total distinct (book, chapter) pairs read, excluding devotional marker. */
    fun totalChaptersReadFlow(): Flow<Int> = dao.distinctChaptersRead()

    /** Total devotional opens (rows where bookName == DEVOTIONAL_BOOK). */
    suspend fun devotionalReadCount(): Int = dao.devotionalCount()

    /** Total foreground reading time in milliseconds, excluding devotionals. */
    suspend fun totalReadingMs(): Long = dao.totalDurationMs()

    /** Distinct chapters read in all three translations (KJV, ASV, WEB). */
    suspend fun chaptersReadInAllVersions(): Int = dao.chaptersInAllVersions()

    /**
     * Current streak in days. Allows one missed day per rolling 7-day window
     * — matches iOS [currentStreakWithFreeze]. Streak must include today or
     * yesterday to be considered alive.
     */
    suspend fun currentStreakWithFreeze(): StreakInfo {
        val sessions = dao.allByDay()
        if (sessions.isEmpty()) return StreakInfo(0, false)

        val daySet = sessions.map { it.dayEpoch }.toSet()
        val today = startOfDay(System.currentTimeMillis())
        val oneDayMs = 24L * 60 * 60 * 1000
        val yesterday = today - oneDayMs

        if (today !in daySet && yesterday !in daySet) return StreakInfo(0, false)

        var lookback = if (today in daySet) 0 else 1
        var streak = 0
        var lastFreezeLookback = -8
        while (true) {
            val targetDay = today - lookback * oneDayMs
            when {
                targetDay in daySet -> {
                    streak += 1
                    lookback += 1
                }
                isSunday(targetDay) -> {
                    // Sabbath rest: a missed Sunday never breaks the streak and
                    // doesn't consume the weekly freeze. Strictly more lenient —
                    // no existing streak is shortened; a read Sunday still counts
                    // (handled by the daySet branch above).
                    lookback += 1
                }
                (lookback - lastFreezeLookback) >= 7 -> {
                    lastFreezeLookback = lookback
                    lookback += 1
                }
                else -> break
            }
        }
        val freezeActive = lastFreezeLookback in 0 until 7
        return StreakInfo(streak, freezeActive)
    }

    /** Longest streak ever — no freeze logic, just consecutive day runs. */
    suspend fun longestStreak(): Int {
        val sessions = dao.allByDay()
        val days = sessions.map { it.dayEpoch }.toSortedSet().toList()
        if (days.isEmpty()) return 0
        val oneDayMs = 24L * 60 * 60 * 1000
        var longest = 1
        var current = 1
        for (i in 1 until days.size) {
            if (days[i] - days[i - 1] == oneDayMs) {
                current += 1
                if (current > longest) longest = current
            } else {
                current = 1
            }
        }
        return longest
    }

    /** Count of reading events grouped by day-epoch over the last N weeks. */
    suspend fun dailyReadingCounts(weeks: Int): Map<Long, Int> {
        val oneDayMs = 24L * 60 * 60 * 1000
        val cutoff = startOfDay(System.currentTimeMillis()) - (weeks * 7L - 1) * oneDayMs
        val sessions = dao.since(cutoff)
        return sessions.groupingBy { it.dayEpoch }.eachCount()
    }

    fun recentSessionsFlow(limit: Int = 20): Flow<List<ReadingSession>> =
        dao.recent(limit).map { rows -> rows.filter { it.bookName != DEVOTIONAL_BOOK } }

    companion object {
        const val DEVOTIONAL_BOOK = "__devotional__"
        const val DEVOTIONAL_VERSION = "devotional"
        const val READ_THRESHOLD_MS = 30_000L

        fun startOfDay(epochMs: Long): Long {
            val cal = Calendar.getInstance()
            cal.timeInMillis = epochMs
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }

        fun isSunday(epochMs: Long): Boolean {
            val cal = Calendar.getInstance()
            cal.timeInMillis = epochMs
            return cal.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY
        }
    }
}

data class StreakInfo(val streak: Int, val freezeActive: Boolean)
