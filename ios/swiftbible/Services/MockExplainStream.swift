//
//  MockExplainStream.swift
//  swiftbible
//
//  DEBUG-only canned-response streamer used to record the Explain demo
//  video for the onboarding feature. Apple Intelligence is unreliable in
//  the iOS Simulator (`GenerationError -1`), so a deterministic mock lets
//  us capture the same streaming UX users will see on a real device.
//
//  Activated by launching with the env var `MOCK_EXPLAIN=1`. The whole
//  file is gated by `#if DEBUG`, so it never compiles into a release
//  build.
//

#if DEBUG
import Foundation

enum MockExplainStream {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["MOCK_EXPLAIN"] == "1"
    }

    /// Tokens-per-second used for the typing animation. Tuned to feel like
    /// a real on-device stream — fast enough to read along, slow enough to
    /// look generative.
    private static let tokensPerSecond: Double = 28
    private static let tokenInterval: UInt64 = UInt64(1_000_000_000.0 / tokensPerSecond)

    private static let explanationBody: String = """
    This opening verse establishes the Bible's foundational claim: God exists \
    before creation and is its sovereign author. The Hebrew word *bara*, \
    translated "created," is reserved in Scripture for divine creative action — \
    signalling that this is no human craftsmanship but a unique act of God.

    Three pillars rest on this single sentence: God is *eternal* (he was "in \
    the beginning"), God is *creator* (everything else is created), and the \
    cosmos is *purposeful* — the heavens and the earth are the deliberate \
    result of his work, not the product of accident or chaos.
    """

    private static let followUpBody: String = """
    Yes — the rabbis observed that *bara* (created) appears only with God as \
    its subject in Genesis 1, while later verses use *yatsar* (formed) and \
    *asah* (made) for ordinary work. The distinction signals that creation \
    *ex nihilo* — out of nothing — is uniquely God's act, not something humans \
    or even angels can replicate.
    """

    static func explanation(
        for request: VerseExplanationRequest
    ) -> AsyncThrowingStream<String, Error> {
        stream(text: explanationBody)
    }

    static func followUp(prompt: String) -> AsyncThrowingStream<String, Error> {
        stream(text: followUpBody)
    }

    /// Emit the body as a stream of small token-sized chunks, sleeping
    /// between each so the UI animates the typewriter effect the same way
    /// the real FoundationModels stream does.
    private static func stream(text: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let tokens = tokenize(text)
                for token in tokens {
                    if Task.isCancelled { break }
                    continuation.yield(token)
                    try? await Task.sleep(nanoseconds: tokenInterval)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Split on whitespace boundaries while preserving the spaces, so the
    /// rendered text reads naturally as it streams in.
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character.isWhitespace {
                tokens.append(current)
                current = ""
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
#endif
