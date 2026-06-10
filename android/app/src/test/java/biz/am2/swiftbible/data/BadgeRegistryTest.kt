package biz.am2.swiftbible.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Guards the pure unlock-threshold data in [BadgeRegistry] that
 * [BadgeService.evaluate] relies on: every track/tier combination must have
 * a positive, strictly increasing threshold, and ids must stay unique
 * (they are the [EarnedBadge] primary key and the iOS sync contract).
 */
class BadgeRegistryTest {

    @Test
    fun `every badge id is unique`() {
        val ids = BadgeRegistry.all.map { it.id }
        assertEquals(ids.size, ids.toSet().size)
    }

    @Test
    fun `tiers cover every track and tier combination exactly once`() {
        assertEquals(BadgeTrack.values().size * BadgeTier.values().size, BadgeRegistry.tiers.size)
        for (track in BadgeTrack.values()) {
            for (tier in BadgeTier.values()) {
                assertEquals(1, BadgeRegistry.tiers.count { it.track == track && it.tier == tier })
            }
        }
    }

    @Test
    fun `every tier badge carries its track, tier, and threshold`() {
        for (def in BadgeRegistry.tiers) {
            assertEquals(BadgeCategory.TIER, def.category)
            assertNotNull("track missing on ${def.id}", def.track)
            assertNotNull("tier missing on ${def.id}", def.tier)
            assertEquals(BadgeRegistry.threshold(def.track!!, def.tier!!), def.threshold)
        }
    }

    @Test
    fun `every track and tier combination has a positive threshold`() {
        // The threshold table ends in an `else -> 0` arm; a zero would mean a
        // newly added track/tier was forgotten and the badge unlocks instantly.
        for (track in BadgeTrack.values()) {
            for (tier in BadgeTier.values()) {
                assertTrue(
                    "threshold for $track/$tier must be positive",
                    BadgeRegistry.threshold(track, tier) > 0,
                )
            }
        }
    }

    @Test
    fun `thresholds increase strictly with tier order within each track`() {
        val orderedTiers = BadgeTier.values().sortedBy { it.order }
        for (track in BadgeTrack.values()) {
            val thresholds = orderedTiers.map { BadgeRegistry.threshold(track, it) }
            for (i in 1 until thresholds.size) {
                assertTrue(
                    "$track thresholds must increase: $thresholds",
                    thresholds[i] > thresholds[i - 1],
                )
            }
        }
    }

    @Test
    fun `spot check canonical thresholds`() {
        assertEquals(7, BadgeRegistry.threshold(BadgeTrack.STREAK, BadgeTier.BRONZE))
        assertEquals(365, BadgeRegistry.threshold(BadgeTrack.STREAK, BadgeTier.DIAMOND))
        // 1,189 chapters and 66 books: the whole Protestant canon.
        assertEquals(1189, BadgeRegistry.threshold(BadgeTrack.CHAPTERS, BadgeTier.DIAMOND))
        assertEquals(66, BadgeRegistry.threshold(BadgeTrack.BOOKS, BadgeTier.DIAMOND))
    }

    @Test
    fun `collectibles and hidden badges have no tier metadata`() {
        for (def in BadgeRegistry.collectibles + BadgeRegistry.hidden) {
            assertNull("unexpected track on ${def.id}", def.track)
            assertNull("unexpected tier on ${def.id}", def.tier)
            assertNull("unexpected threshold on ${def.id}", def.threshold)
        }
    }

    @Test
    fun `definition lookup finds known ids and rejects unknown ones`() {
        assertEquals("collect.gospels", BadgeRegistry.definition("collect.gospels")?.id)
        assertEquals(
            "tier.streak.bronze",
            BadgeRegistry.tier(BadgeTrack.STREAK, BadgeTier.BRONZE).id,
        )
        assertNull(BadgeRegistry.definition("no.such.badge"))
    }
}
