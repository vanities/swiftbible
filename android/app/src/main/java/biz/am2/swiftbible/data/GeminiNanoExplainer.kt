package biz.am2.swiftbible.data

import android.util.Log
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.withContext

/**
 * Bible-verse explanation backed by on-device Gemini Nano (Google AICore) via
 * the ML Kit GenAI Prompt API.
 *
 * Devices with Gemini Nano support (Pixel 8 Pro, Pixel 9 / 10 series, Galaxy
 * S24+, and other 2024+ flagships) get a real LLM response; everyone else
 * falls back to a curated static reflection.
 *
 * Inference runs entirely on-device — the verse text never leaves the user's
 * phone. ML Kit GenAI APIs are publicly available (no allowlist) as of 2025.
 */
object GeminiNanoExplainer {

    private const val TAG = "GeminiNano"

    private const val SYSTEM_PROMPT = """You are a thoughtful Bible study companion. Given a Bible verse, write a concise explanation (2 short paragraphs, ~120 words total) covering:
1. Historical and literary context — who is speaking, to whom, when.
2. Plain meaning of the verse and its place in the broader biblical narrative.
End with one short reflection question. Plain, accessible English. No jargon, no moralizing."""

    private val model: GenerativeModel by lazy { Generation.getClient() }

    /**
     * Snapshot of whether on-device GenAI is usable on this device. Cheap
     * call — safe to invoke from a Composable's `LaunchedEffect`.
     *
     * Returns one of the [FeatureStatus] constants (`AVAILABLE`,
     * `DOWNLOADABLE`, `DOWNLOADING`, `UNAVAILABLE`).
     */
    suspend fun availability(): Int = withContext(Dispatchers.IO) {
        runCatching { model.checkStatus() }.getOrElse { FeatureStatus.UNAVAILABLE }
    }

    /**
     * Whether the device can run Gemini Nano — either the model is already
     * downloaded or downloadable. Used to gate the EXPLAIN onboarding page.
     */
    suspend fun isSupportedOnDevice(): Boolean = when (availability()) {
        FeatureStatus.AVAILABLE,
        FeatureStatus.DOWNLOADABLE,
        FeatureStatus.DOWNLOADING -> true
        else -> false
    }

    /**
     * Kick off the Gemini Nano model download on devices that support it but
     * haven't downloaded the model yet. Safe to call eagerly on app launch —
     * no-ops on UNAVAILABLE devices and doesn't throw. Suspends until the
     * download stream completes (or errors), which can take minutes; callers
     * should run this in a background scope.
     */
    suspend fun prefetchModel(): Unit = withContext(Dispatchers.IO) {
        runCatching {
            if (model.checkStatus() == FeatureStatus.DOWNLOADABLE) {
                model.download().catch { Log.w(TAG, "GenAI model download failed", it) }.collect { }
            }
        }
    }

    suspend fun explain(verseRef: String, verseText: String): String =
        withContext(Dispatchers.IO) {
            when (availability()) {
                FeatureStatus.AVAILABLE -> generateOrFallback(verseRef, verseText)
                FeatureStatus.DOWNLOADABLE, FeatureStatus.DOWNLOADING ->
                    "${fallbackText()}\n\n_The on-device AI model is downloading. Try again in a few minutes for a personalized explanation._"
                else -> fallbackText()
            }
        }

    private suspend fun generateOrFallback(verseRef: String, verseText: String): String {
        val prompt = "${SYSTEM_PROMPT.trim()}\n\nVerse: $verseRef\nText: \"$verseText\""
        return runCatching {
            model.generateContent(prompt).candidates.firstOrNull()?.text
        }.getOrNull()?.takeIf { it.isNotBlank() } ?: fallbackText()
    }

    private fun fallbackText(): String =
        """
        This verse sits within a longer passage; reading the surrounding chapter will surface its full meaning. The plain reading invites us to slow down and notice each phrase before reaching for application.

        A useful question: what would change in your day if you read this verse as if it were addressed personally to you?
        """.trimIndent()
}
