package biz.am2.swiftbible.data

import kotlinx.coroutines.delay

/**
 * Stub for Google's on-device generative AI ("AICore" / Gemini Nano).
 *
 * The real Android AICore SDK is in early access via Google's restricted preview
 * (https://developer.android.com/ai/aicore). To use it, an app must:
 *   1. Be allowlisted by Google
 *   2. Add the AICore client library + manifest declarations
 *   3. Run on a device that ships with AICore (Pixel 8 Pro, Pixel 9 series,
 *      Galaxy S24 series, etc.)
 *
 * Until then, this stub returns a structured-but-static reflection. Swap the
 * body of [explain] with the real AICore call when you're ready:
 *
 *   val client = GenerativeModel.Builder(InferenceMode.PREFER_ON_DEVICE)
 *       .setSystemInstruction(SYSTEM_PROMPT)
 *       .build()
 *   client.generateContent("Explain $verseRef: $verseText").text
 *
 * The on-device model is private — the verse text never leaves the user's phone.
 */
object GeminiNanoExplainer {

    private const val SYSTEM_PROMPT = """
You are a thoughtful Bible study companion. Given a Bible verse reference and
its text, write a brief explanation (3–5 short paragraphs) covering:
1. The historical/literary context (who is speaking, to whom, when)
2. The plain meaning of the verse
3. A connection to the broader biblical narrative
4. A reflection question for the reader.
Use clear, accessible English. Avoid jargon. Don't moralize.
"""

    suspend fun explain(verseRef: String, verseText: String): String {
        // Simulate latency
        delay(800)
        return """
**$verseRef**

> $verseText

This verse sits within a longer passage; reading the surrounding chapter will surface its full meaning. The plain reading invites us to slow down and notice each phrase before reaching for application.

A useful question: what would change in your day if you read this verse as if it were addressed personally to you?

(On-device AI explanations powered by Google's AICore are coming soon. Until then, this is a placeholder reflection.)
        """.trimIndent()
    }
}
