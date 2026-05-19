package biz.am2.swiftbible.data

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Compact rolling log of devotional opens so the All Voices and Series
 * Completionist hidden badges can evaluate against recent history. Mirrors
 * iOS DevotionalHistory. Backed by a dedicated SharedPreferences key so
 * it stays separate from UserPreferences and won't bloat that snapshot.
 */
object DevotionalHistory {
    private const val PREFS_NAME = "devotional_history_v1"
    private const val KEY_HISTORY = "history"
    private const val MAX_ENTRIES = 200

    data class View(
        val timestamp: Long,
        val track: String?,
        val seriesName: String?,
        val seriesPart: Int?,
    )

    fun record(context: Context, track: String?, seriesName: String?, seriesPart: Int?) {
        val prefs = prefs(context)
        val history = load(prefs).toMutableList()
        history.add(View(System.currentTimeMillis(), track, seriesName, seriesPart))
        while (history.size > MAX_ENTRIES) history.removeAt(0)
        save(prefs, history)
    }

    /** Distinct AI track names viewed in the trailing window. */
    fun tracksInLast(context: Context, days: Int): Set<String> {
        val cutoff = System.currentTimeMillis() - days.toLong() * 24L * 60 * 60 * 1000
        return load(prefs(context))
            .filter { it.timestamp >= cutoff }
            .mapNotNull { it.track }
            .toSet()
    }

    /** Series-name → set of parts viewed; used for Series Completionist. */
    fun seriesProgress(context: Context): Map<String, Set<Int>> {
        val map = mutableMapOf<String, MutableSet<Int>>()
        for (view in load(prefs(context))) {
            val name = view.seriesName ?: continue
            val part = view.seriesPart ?: continue
            map.getOrPut(name) { mutableSetOf() }.add(part)
        }
        return map
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun load(prefs: SharedPreferences): List<View> {
        val raw = prefs.getString(KEY_HISTORY, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                View(
                    timestamp = o.getLong("ts"),
                    track = o.optString("track").takeIf { it.isNotEmpty() },
                    seriesName = o.optString("series").takeIf { it.isNotEmpty() },
                    seriesPart = if (o.has("part")) o.getInt("part") else null,
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun save(prefs: SharedPreferences, history: List<View>) {
        val arr = JSONArray()
        for (v in history) {
            val o = JSONObject().apply {
                put("ts", v.timestamp)
                v.track?.let { put("track", it) }
                v.seriesName?.let { put("series", it) }
                v.seriesPart?.let { put("part", it) }
            }
            arr.put(o)
        }
        prefs.edit().putString(KEY_HISTORY, arr.toString()).apply()
    }
}
