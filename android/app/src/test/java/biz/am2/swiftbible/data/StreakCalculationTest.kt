package biz.am2.swiftbible.data

import java.util.Calendar
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Exercises the pure streak math in [ReadingStatsRepository]'s companion:
 * [ReadingStatsRepository.computeStreakWithFreeze] (one missed day allowed
 * per rolling 7-day window; missed Sundays never break nor consume the
 * freeze; streak must include today or yesterday to be alive) and
 * [ReadingStatsRepository.computeLongestStreak] (plain consecutive runs).
 */
class StreakCalculationTest {

    private val oneDay = 24L * 60 * 60 * 1000

    /** Start-of-day epoch for a fixed date in the default timezone. */
    private fun day(year: Int, month: Int, dayOfMonth: Int): Long {
        val cal = Calendar.getInstance()
        cal.clear()
        cal.set(year, month, dayOfMonth)
        return cal.timeInMillis
    }

    // 2026-06-10 is a Wednesday. Early June has no DST transitions in any
    // common timezone, so stepping in exact 24h increments stays aligned
    // with calendar days (and with the Sunday check) on every machine.
    private val today = day(2026, Calendar.JUNE, 10)

    /** Start-of-day epoch [n] days before the anchored Wednesday. */
    private fun daysAgo(n: Int): Long = today - n * oneDay

    // MARK: - computeStreakWithFreeze

    @Test
    fun `empty day set has no streak`() {
        val info = ReadingStatsRepository.computeStreakWithFreeze(emptySet(), today)
        assertEquals(0, info.streak)
        assertFalse(info.freezeActive)
    }

    @Test
    fun `single read today is a one day streak`() {
        val info = ReadingStatsRepository.computeStreakWithFreeze(setOf(today), today)
        assertEquals(1, info.streak)
    }

    @Test
    fun `consecutive days ending today all count`() {
        val days = (0..4).map { daysAgo(it) }.toSet()
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(5, info.streak)
    }

    @Test
    fun `streak read yesterday but not yet today is still alive`() {
        val days = setOf(daysAgo(1), daysAgo(2), daysAgo(3))
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(3, info.streak)
    }

    @Test
    fun `streak is dead when the last read was two or more days ago`() {
        val days = setOf(daysAgo(2), daysAgo(3), daysAgo(4))
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(0, info.streak)
        assertFalse(info.freezeActive)
    }

    @Test
    fun `one missed weekday is bridged by the freeze`() {
        // Wed read, Tue missed (freeze), Mon read, Sun missed (sabbath rest),
        // Sat read — streak spans all five days' worth of reads.
        val days = setOf(today, daysAgo(2), daysAgo(4))
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(3, info.streak)
        assertTrue(info.freezeActive)
    }

    @Test
    fun `two missed weekdays in the same window break the streak`() {
        // Wed read; Tue missed consumes the freeze; Mon missed (not a Sunday,
        // freeze spent) breaks — the Fri read no longer connects.
        val days = setOf(today, daysAgo(5))
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(1, info.streak)
    }

    @Test
    fun `missed sunday never breaks the streak nor consumes the freeze`() {
        // Wed..Mon read, Sunday missed, Sat+Fri read: five reads bridge the
        // missed Sunday with the freeze still unspent inside the streak.
        val days = setOf(today, daysAgo(1), daysAgo(2), daysAgo(4), daysAgo(5))
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(5, info.streak)
    }

    @Test
    fun `freeze rearms after seven days of lookback`() {
        // Wed read, Tue missed (freeze #1 at lookback 1), Mon Jun 8 through
        // Wed Jun 3 read (6 reads), Tue Jun 2 missed again at lookback 8 —
        // 7 lookback days after freeze #1, so the freeze has re-armed — and
        // Mon Jun 1 still counts: 8 reads in total.
        val days = setOf(
            today, // Wed Jun 10
            daysAgo(2), // Mon Jun 8
            daysAgo(3), // Sun Jun 7
            daysAgo(4), // Sat Jun 6
            daysAgo(5), // Fri Jun 5
            daysAgo(6), // Thu Jun 4
            daysAgo(7), // Wed Jun 3
            // Tue Jun 2 missed: lookback 8, freeze re-armed (8 - 1 >= 7)
            daysAgo(9), // Mon Jun 1
        )
        val info = ReadingStatsRepository.computeStreakWithFreeze(days, today)
        assertEquals(8, info.streak)
    }

    // MARK: - computeLongestStreak

    @Test
    fun `longest streak of nothing is zero`() {
        assertEquals(0, ReadingStatsRepository.computeLongestStreak(emptyList()))
    }

    @Test
    fun `longest streak of a single day is one`() {
        assertEquals(1, ReadingStatsRepository.computeLongestStreak(listOf(0L)))
    }

    @Test
    fun `consecutive days count without freeze leniency`() {
        val days = (0L..3L).map { it * oneDay }
        assertEquals(4, ReadingStatsRepository.computeLongestStreak(days))
    }

    @Test
    fun `a gap breaks the run`() {
        val days = listOf(0L, 1L, 2L, 4L, 5L).map { it * oneDay }
        assertEquals(3, ReadingStatsRepository.computeLongestStreak(days))
    }

    @Test
    fun `longest run wins across gaps even when it is not the latest`() {
        val days = (listOf(0L, 1L, 2L, 3L, 4L) + listOf(10L, 11L)).map { it * oneDay }
        assertEquals(5, ReadingStatsRepository.computeLongestStreak(days))
    }

    @Test
    fun `duplicate days collapse instead of inflating the run`() {
        val days = listOf(0L, 0L, 1L, 1L, 2L).map { it * oneDay }
        assertEquals(3, ReadingStatsRepository.computeLongestStreak(days))
    }

    @Test
    fun `unsorted input is handled`() {
        val days = listOf(2L, 0L, 1L).map { it * oneDay }
        assertEquals(3, ReadingStatsRepository.computeLongestStreak(days))
    }
}
