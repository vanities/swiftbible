package biz.am2.swiftbible.data

import java.util.Calendar

/**
 * Computes liturgical dates needed by hidden badges. Easter uses the
 * Anonymous Gregorian (Meeus/Jones/Butcher) algorithm; Pentecost is
 * 49 days after Easter; Christmas is fixed. Mirrors iOS
 * `LiturgicalCalendar.swift`.
 */
object LiturgicalCalendar {

    fun easterSunday(year: Int): Calendar? {
        val a = year % 19
        val b = year / 100
        val c = year % 100
        val d = b / 4
        val e = b % 4
        val f = (b + 8) / 25
        val g = (b - f + 1) / 3
        val h = (19 * a + b - d - g + 15) % 30
        val i = c / 4
        val k = c % 4
        val l = (32 + 2 * e + 2 * i - h - k) % 7
        val m = (a + 11 * h + 22 * l) / 451
        val month = (h + l - 7 * m + 114) / 31
        val day = ((h + l - 7 * m + 114) % 31) + 1
        return Calendar.getInstance().apply {
            set(year, month - 1, day, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    fun pentecost(year: Int): Calendar? = easterSunday(year)?.apply {
        add(Calendar.DAY_OF_YEAR, 49)
    }

    fun isEaster(epochMs: Long): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        val year = cal.get(Calendar.YEAR)
        val easter = easterSunday(year) ?: return false
        return sameDay(cal, easter)
    }

    fun isPentecost(epochMs: Long): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        val year = cal.get(Calendar.YEAR)
        val pent = pentecost(year) ?: return false
        return sameDay(cal, pent)
    }

    fun isChristmas(epochMs: Long): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        return cal.get(Calendar.MONTH) == Calendar.DECEMBER && cal.get(Calendar.DAY_OF_MONTH) == 25
    }

    private fun sameDay(a: Calendar, b: Calendar): Boolean =
        a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
        a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
}
