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
    This short verse closes a striking moment in Nehemiah's restoration narrative. \
    The people who chose to dwell in Jerusalem were not coerced — they "willingly \
    offered themselves." The community responded by *blessing* them, recognising \
    that the work of rebuilding required more than walls; it required willing hearts.

    Three things stand out: the freedom of the choice, the sacrifice it implied \
    (Jerusalem was less prosperous than the surrounding cities), and the public \
    affirmation that followed. The verse quietly honours people who step into \
    hard, often unseen work for the sake of the wider community.
    """

    private static let followUpBody: String = """
    Yes — the language of "willingly offered" echoes earlier covenant moments \
    where God's people brought freewill offerings (Exodus 35, 1 Chronicles 29). \
    Nehemiah is signalling continuity: this generation, like their ancestors, \
    is restoring worship through voluntary devotion rather than compulsion.
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
