package biz.am2.swiftbible.ui

import biz.am2.swiftbible.data.BadgeDefinition
import biz.am2.swiftbible.data.BadgeRegistry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * App-wide queue of badge-earned toasts. The root layout collects [queue]
 * as state and renders the head item; advancing happens via [dismissFirst].
 * Mirrors iOS ToastService.
 */
object ToastCoordinator {
    private val _queue = MutableStateFlow<List<BadgeDefinition>>(emptyList())
    val queue = _queue.asStateFlow()

    fun enqueue(badge: BadgeDefinition) {
        val current = _queue.value
        if (current.any { it.id == badge.id }) return
        _queue.value = current + badge
    }

    fun dismissFirst() {
        val current = _queue.value
        if (current.isEmpty()) return
        _queue.value = current.drop(1)
    }

    /** Cycles sample badges in DEBUG so the toast can be inspected. */
    private var debugIndex = 0
    private val debugSamples = listOf(
        "tier.streak.bronze",
        "collect.gospels",
        "hidden.night.owl",
        "tier.books.gold",
    )

    fun enqueueDebugSample() {
        val id = debugSamples[debugIndex % debugSamples.size]
        debugIndex += 1
        BadgeRegistry.definition(id)?.let { enqueue(it) }
    }
}
