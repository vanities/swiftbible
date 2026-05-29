package biz.am2.swiftbible.data

import android.content.Context
import biz.am2.swiftbible.ui.theme.BrandAccent
import biz.am2.swiftbible.ui.theme.BrandGold
import biz.am2.swiftbible.ui.theme.BrandRedDark
import androidx.compose.ui.graphics.Color
import java.time.LocalDate

data class ScriptureRef(val book: String, val chapter: Int, val startVerse: Int, val endVerse: Int? = null) {
    val displayLabel: String
        get() = if (endVerse != null && endVerse > startVerse) "$book $chapter:$startVerse-$endVerse"
        else "$book $chapter:$startVerse"
}

data class EventReadingDay(
    val id: String,
    val date: LocalDate,
    val theme: String,
    val passage: ScriptureRef,
    val reflection: String,
)

enum class EventAccent(val color: Color) {
    GOLD(BrandGold), RED(BrandRedDark), ACCENT(BrandAccent);
}

sealed class EventAction {
    data class OpenVerse(val book: String, val chapter: Int, val verse: Int) : EventAction()
    data object OpenDevotional : EventAction()
    data object OpenEvent : EventAction()
}

data class AppEvent(
    val id: String,
    val name: String,
    val subtitle: String,
    val iconEmoji: String,
    val accent: EventAccent,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val action: EventAction,
    @androidx.annotation.DrawableRes val bannerRes: Int? = null,
    val readingPlan: List<EventReadingDay> = emptyList(),
) {
    fun isActive(today: LocalDate = LocalDate.now()): Boolean =
        !today.isBefore(startDate) && !today.isAfter(endDate)
}

object AppEventRegistry {
    val pentecost2026 = AppEvent(
        id = "pentecost-2026",
        name = "Pentecost Reading Plan",
        subtitle = "Acts 2 — through June 7",
        iconEmoji = "🔥",
        accent = EventAccent.GOLD,
        startDate = LocalDate.of(2026, 5, 25),
        // Card lingers ~a week past the App Store event_end (Jun 7) so the
        // finished plan stays reachable for stragglers, then drops off More.
        endDate = LocalDate.of(2026, 6, 14),
        action = EventAction.OpenEvent,
        bannerRes = biz.am2.swiftbible.R.drawable.pentecost_event,
        readingPlan = pentecostReadingPlan,
    )

    val summerPsalms2026 = AppEvent(
        id = "summer-psalms-2026",
        name = "Summer in the Psalms",
        subtitle = "A psalm a day — through July",
        iconEmoji = "☀️",
        accent = EventAccent.ACCENT,
        startDate = LocalDate.of(2026, 7, 1),
        // Card lingers ~a week past the App Store event_end (Jul 30).
        endDate = LocalDate.of(2026, 8, 6),
        action = EventAction.OpenEvent,
        bannerRes = biz.am2.swiftbible.R.drawable.summer_psalms_event,
        readingPlan = summerPsalmsReadingPlan,
    )

    fun todayReadingIndex(event: AppEvent, today: LocalDate = LocalDate.now()): Int {
        if (event.readingPlan.isEmpty()) return 0
        val match = event.readingPlan.indexOfFirst { it.date == today }
        if (match >= 0) return match
        val upcoming = event.readingPlan.indexOfFirst { !it.date.isBefore(today) }
        if (upcoming >= 0) return upcoming
        return event.readingPlan.size - 1
    }

    val all: List<AppEvent> = listOf(pentecost2026, summerPsalms2026)

    fun visible(today: LocalDate = LocalDate.now(), forceAll: Boolean = false): List<AppEvent> =
        if (forceAll) all else all.filter { it.isActive(today) }

    fun byId(id: String): AppEvent? = all.firstOrNull { it.id == id }
}

/**
 * Tracks which event reading-plan days the user has completed (viewed while
 * unlocked). Backed by a dedicated SharedPreferences key, mirroring the iOS
 * `completedEventDayIDs` AppStorage. BadgeService reads this to award the
 * per-event "finished the plan" collectibles.
 */
object EventProgress {
    private const val PREFS = "event_progress"
    private const val KEY = "completedDayIds"

    fun completedDayIds(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY, emptySet()) ?: emptySet()

    fun markCompleted(context: Context, dayId: String) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val current = prefs.getStringSet(KEY, emptySet())?.toMutableSet() ?: mutableSetOf()
        if (current.add(dayId)) {
            prefs.edit().putStringSet(KEY, current).apply()
        }
    }
}
