package biz.am2.swiftbible.ui

import biz.am2.swiftbible.ui.components.AIAttribution
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The devotional row's `model` column is rendered into the AI-attribution
 * disclosure the user reads. When the Edge Function moved from gpt-5.4 to the
 * GPT-5.6 family (Sol/Terra/Luna), the old renderer did a naive "gpt-" ->
 * "GPT-" swap, which turned "gpt-5.6-terra" into "GPT-5.6-terra".
 *
 * Mirrors ios/swiftbibleTests/AIAttributionTests.swift.
 */
class AIAttributionTest {

    @Test
    fun `tiered model id renders with spaced capitalized tier`() {
        assertEquals("GPT-5.6 Terra", AIAttribution.displayName("gpt-5.6-terra"))
        assertEquals("GPT-5.6 Sol", AIAttribution.displayName("gpt-5.6-sol"))
        assertEquals("GPT-5.6 Luna", AIAttribution.displayName("gpt-5.6-luna"))
    }

    @Test
    fun `tiered model id does not leak a hyphenated tier`() {
        assertTrue(!AIAttribution.displayName("gpt-5.6-terra").contains("5.6-terra"))
    }

    @Test
    fun `two part model id still renders`() {
        assertEquals("GPT-5.4", AIAttribution.displayName("gpt-5.4"))
    }

    @Test
    fun `legacy mini id renders`() {
        assertEquals("GPT-5.4 Mini", AIAttribution.displayName("gpt-5.4-mini"))
    }

    @Test
    fun `null and empty fall back to the current model`() {
        assertEquals(AIAttribution.FALLBACK_MODEL, AIAttribution.displayName(null))
        assertEquals(AIAttribution.FALLBACK_MODEL, AIAttribution.displayName(""))
    }

    @Test
    fun `fallback is the current generation model`() {
        assertEquals("GPT-5.6 Terra", AIAttribution.FALLBACK_MODEL)
    }
}
