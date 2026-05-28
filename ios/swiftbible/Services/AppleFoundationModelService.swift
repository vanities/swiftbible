//
//  AppleFoundationModelService.swift
//  swiftbible
//
//  Created by OpenAI.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleFoundationModelServiceError: LocalizedError {
    case modelUnavailable(reason: String)
    case contentFiltered
    case generationFailed(underlying: String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence is currently unavailable: \(reason)."
        case .contentFiltered:
            return "Apple Intelligence's on-device safety filter blocked this passage. This sometimes happens with passages that touch on sensitive topics even in a biblical context. Try rephrasing your question, or consult another trusted commentary."
        case .generationFailed(let underlying):
            return "Apple Intelligence couldn't generate a response. \(underlying)"
        }
    }

    static func isGuardrailError(_ error: Error) -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            for candidate in unwrapErrors(error) {
                if let generationError = candidate as? LanguageModelSession.GenerationError,
                   case .guardrailViolation = generationError {
                    return true
                }
            }
        }
        #endif
        // Fallback: some guardrail errors may be surfaced wrapped or as NSError
        // descriptions, so keep a string-based safety net. The typed match above
        // is the source of truth when it fires.
        let description = String(describing: error).lowercased()
        return description.contains("guardrail")
            || description.contains("may contain sensitive")
            || description.contains("unsafe content")
    }

    /// Walk a wrapped error (NSError with `NSUnderlyingErrorKey` /
    /// `NSMultipleUnderlyingErrorsKey`) and return every error encountered,
    /// including the root. FoundationModels bridges GenerationError into
    /// NSError with code -1 and buries the real cases in userInfo, so we have
    /// to dig to recover the typed Swift case.
    static func unwrapErrors(_ error: Error) -> [Error] {
        var results: [Error] = []
        var queue: [Error] = [error]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            results.append(current)
            let nsError = current as NSError
            if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                queue.append(underlying)
            }
            if let multiple = nsError.userInfo[NSMultipleUnderlyingErrorsKey] as? [Error] {
                queue.append(contentsOf: multiple)
            }
        }
        return results
    }

    /// Turn any error surfaced by FoundationModels into a user-friendly
    /// `AppleFoundationModelServiceError`. Without this, GenerationError
    /// bridges to NSError with a useless "error -1" `localizedDescription`.
    static func friendly(_ error: Error) -> AppleFoundationModelServiceError {
        if let mapped = error as? AppleFoundationModelServiceError {
            return mapped
        }

        let candidates = unwrapErrors(error)

        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            for candidate in candidates {
                if let generationError = candidate as? LanguageModelSession.GenerationError {
                    switch generationError {
                    case .guardrailViolation:
                        return .contentFiltered
                    default:
                        // Other cases (assetsUnavailable, decodingFailure,
                        // unsupportedGuide, rateLimited, context-window
                        // exceeded, etc.) — surface a short, human-friendly
                        // summary rather than the raw NSError-bridge string.
                        let summary = shortDescription(for: generationError)
                        return .generationFailed(underlying: summary)
                    }
                }
            }
        }
        #endif

        if isGuardrailError(error) {
            return .contentFiltered
        }

        // Prefer the first underlying NSError's localizedDescription if the
        // outer error is the generic "(null)" NSError-bridge — otherwise the
        // user sees nothing useful.
        let bestMessage = candidates
            .lazy
            .map { ($0 as NSError).localizedDescription }
            .first(where: { !$0.isEmpty && !$0.contains("(null)") })
            ?? error.localizedDescription
        return .generationFailed(underlying: bestMessage)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
    private static func shortDescription(
        for error: LanguageModelSession.GenerationError
    ) -> String {
        // GenerationError cases carry a Context with a debugDescription that's
        // usually informative. Prefer that over String(describing:), which
        // includes the full case payload and nested types.
        let mirror = Mirror(reflecting: error)
        if let child = mirror.children.first?.value,
           let context = Mirror(reflecting: child)
               .descendant("debugDescription") as? String,
           !context.isEmpty {
            return context
        }
        return String(describing: error)
    }
    #endif
}

@MainActor
final class AppleFoundationModelService {
    static let shared = AppleFoundationModelService()

    fileprivate static let instructions = "You are a trusted pastoral Bible commentary assistant helping a reader study Scripture. Offer historically grounded, theologically orthodox insights that respect the passage's canonical context. All passages are reverent biblical texts; treat discussions of covenant signs, warfare narratives, prophetic imagery, and other ancient cultural practices as academic, theological reflection. Write warmly but avoid personal greetings or letters. After the initial commentary, engage follow-up questions conversationally while staying rooted in the same passage."

    enum AvailabilityStatus: Equatable {
        case unsupportedOS
        case available
        case unavailable(reason: String)

        var advisoryMessage: String {
            switch self {
            case .unsupportedOS:
                return "Apple Intelligence requires iOS 26, macOS 26, macCatalyst 26, or visionOS 2."
            case .available:
                return ""
            case .unavailable(let reason):
                return "Apple Intelligence is currently unavailable: \(reason)."
            }
        }

        var isReadyForGeneration: Bool {
            if case .available = self { return true }
            return false
        }
    }

    private init() {}

    var isResponding: Bool {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            return AppleFoundationModelServiceImplementation.shared.isResponding
        }
        return false
    }

    var availabilityStatus: AvailabilityStatus {
        #if DEBUG
        if MockExplainStream.isEnabled { return .available }
        #endif
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            return AppleFoundationModelServiceImplementation.shared.availabilityStatus
        }
        return .unsupportedOS
    }

    func streamExplanation(for request: VerseExplanationRequest) -> AsyncThrowingStream<String, Error> {
        #if DEBUG
        if MockExplainStream.isEnabled {
            return MockExplainStream.explanation(for: request)
        }
        #endif
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            return AppleFoundationModelServiceImplementation.shared.streamExplanation(for: request)
        }

        return AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: AppleFoundationModelServiceError.modelUnavailable(
                    reason: "Requires iOS 26, macOS 26, macCatalyst 26, or visionOS 2."
                )
            )
        }
    }

    func streamFollowUp(prompt: String) -> AsyncThrowingStream<String, Error> {
        #if DEBUG
        if MockExplainStream.isEnabled {
            return MockExplainStream.followUp(prompt: prompt)
        }
        #endif
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            return AppleFoundationModelServiceImplementation.shared.streamFollowUp(prompt: prompt)
        }

        return AsyncThrowingStream { continuation in
            continuation.finish(
                throwing: AppleFoundationModelServiceError.modelUnavailable(
                    reason: "Requires iOS 26, macOS 26, macCatalyst 26, or visionOS 2."
                )
            )
        }
    }

    func resetSession() {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            AppleFoundationModelServiceImplementation.shared.resetSession()
        }
    }

    /// Log a FoundationModels failure to both the console and Sentry, with
    /// enough context that we can diagnose Apple Intelligence errors from
    /// user reports without having to reproduce them. Cancellation errors are
    /// ignored (they're expected when a sheet dismisses mid-stream).
    static func logFailure(
        _ error: Error,
        action: String,
        request: VerseExplanationRequest?
    ) {
        if error is CancellationError { return }

        let chain = AppleFoundationModelServiceError.unwrapErrors(error)
        let rawDescription = String(describing: error)
        let chainDescriptions = chain.enumerated().map { index, candidate -> String in
            let ns = candidate as NSError
            return "[\(index)] \(ns.domain) code=\(ns.code) \(ns.localizedDescription)"
        }

        print("[AppleFoundationModelService] \(action) failed: \(rawDescription)")
        for line in chainDescriptions {
            print("[AppleFoundationModelService]   \(line)")
        }

        var context: [String: Any] = [
            "action": action,
            "rawDescription": rawDescription,
            "errorChain": chainDescriptions.joined(separator: "\n"),
            "chainDepth": "\(chain.count)",
            "isGuardrail": AppleFoundationModelServiceError.isGuardrailError(error)
        ]
        if let request {
            context["reference"] = request.reference
            context["translation"] = request.translation
            context["bookName"] = request.bookName
            context["chapter"] = "\(request.chapter)"
            context["startingVerse"] = "\(request.startingVerse)"
        }
        SentryService.shared.capture(error, context: context)
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
@MainActor
private final class AppleFoundationModelServiceImplementation {
    static let shared = AppleFoundationModelServiceImplementation()

    private let model: SystemLanguageModel
    private var session: LanguageModelSession
    private let generationOptions: GenerationOptions

    private init(model: SystemLanguageModel = .default) {
        self.model = model
        self.session = LanguageModelSession(
            model: model,
            instructions: AppleFoundationModelService.instructions
        )
        self.generationOptions = GenerationOptions(
            sampling: nil,
            temperature: 0.7,
            maximumResponseTokens: 1800
        )
    }

    var isResponding: Bool { session.isResponding }

    var availabilityStatus: AppleFoundationModelService.AvailabilityStatus {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: String(describing: reason))
        @unknown default:
            return .unavailable(reason: "Unknown reason")
        }
    }

    func resetSession() {
        session = LanguageModelSession(
            model: model,
            instructions: AppleFoundationModelService.instructions
        )
    }

    func streamExplanation(for request: VerseExplanationRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            if case .unavailable(let reason) = model.availability {
                let message = String(describing: reason)
                continuation.finish(throwing: AppleFoundationModelServiceError.modelUnavailable(reason: message))
                return
            }

            let streamingTask = Task { @MainActor in
                do {
                    try await self.streamStructuredCommentary(
                        prompt: request.userPrompt,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    if AppleFoundationModelServiceError.isGuardrailError(error) {
                        // Apple's on-device safety filter flagged the literal passage text
                        // (this happens with verses like Genesis 17:11 that mention
                        // circumcision, and other passages touching on sensitive topics).
                        // Reset the session so the flagged context is cleared, then retry
                        // with a softer reference-only prompt.
                        SentryService.shared.addBreadcrumb(
                            category: "appleFoundationModel",
                            message: "Guardrail hit on primary prompt, retrying with fallback",
                            level: .warning
                        )
                        self.resetSession()
                        do {
                            try await self.streamStructuredCommentary(
                                prompt: request.fallbackUserPrompt,
                                continuation: continuation
                            )
                            continuation.finish()
                        } catch is CancellationError {
                            continuation.finish()
                        } catch {
                            AppleFoundationModelService.logFailure(
                                error,
                                action: "streamExplanation.fallback",
                                request: request
                            )
                            continuation.finish(throwing: AppleFoundationModelServiceError.friendly(error))
                        }
                    } else {
                        AppleFoundationModelService.logFailure(
                            error,
                            action: "streamExplanation",
                            request: request
                        )
                        continuation.finish(throwing: AppleFoundationModelServiceError.friendly(error))
                    }
                }
            }

            continuation.onTermination = { _ in
                streamingTask.cancel()
            }
        }
    }

    private func streamStructuredCommentary(
        prompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let stream = session.streamResponse(
            to: prompt,
            generating: VerseCommentary.self,
            options: generationOptions
        )

        var lastExplanation = ""

        // partial is the snapshot: properties are optional as the response streams.
        for try await partial in stream {
            let explanation = Self.render(commentary: partial.content)
            let delta: String
            if explanation.hasPrefix(lastExplanation) {
                delta = String(explanation.dropFirst(lastExplanation.count))
            } else {
                delta = explanation
            }
            lastExplanation = explanation
            guard !delta.isEmpty else { continue }
            continuation.yield(delta)
        }
    }

    private func streamPlainText(
        prompt: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let stream = session.streamResponse(to: prompt, options: generationOptions)
        var lastText = ""
        for try await partial in stream {
            let text = partial.content
            let delta: String
            if text.hasPrefix(lastText) {
                delta = String(text.dropFirst(lastText.count))
            } else {
                delta = text
            }
            lastText = text
            guard !delta.isEmpty else { continue }
            continuation.yield(delta)
        }
    }

    func streamFollowUp(prompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            if case .unavailable(let reason) = model.availability {
                let message = String(describing: reason)
                continuation.finish(throwing: AppleFoundationModelServiceError.modelUnavailable(reason: message))
                return
            }

            let streamingTask = Task { @MainActor in
                do {
                    try await self.streamPlainText(prompt: prompt, continuation: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    AppleFoundationModelService.logFailure(
                        error,
                        action: "streamFollowUp",
                        request: nil
                    )
                    continuation.finish(throwing: AppleFoundationModelServiceError.friendly(error))
                }
            }

            continuation.onTermination = { _ in
                streamingTask.cancel()
            }
        }
    }
}

@available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
private extension AppleFoundationModelServiceImplementation {
    static func render(commentary: VerseCommentary.PartiallyGenerated) -> String {
        var sections: [String] = []

        if let summary = trimmedNonEmpty(commentary.summary) {
            sections.append(summary)
        }

        func appendSection(title: String, value: String?) {
            guard let trimmed = trimmedNonEmpty(value) else { return }
            sections.append("\(title)\n\(trimmed)")
        }

        appendSection(title: "Context", value: commentary.context)
        appendSection(title: "Theology", value: commentary.theology)
        appendSection(title: "Application", value: commentary.application)
        appendSection(title: "Literary Notes", value: commentary.literary)
        appendSection(title: "Historical & Authorship Notes", value: commentary.history)

        return sections.joined(separator: "\n\n")
    }
}
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
@inline(__always)
func trimmedNonEmpty(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
        return nil
    }
    return value
}
#endif

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
@Generable
private struct VerseCommentary {
    @Guide(description: "1-2 sentences that cite the passage in parentheses (for example '(John 3:16)') and summarize the central idea in warm, pastoral language.")
    var summary: String

    @Guide(description: "Historical or literary context that situates the passage (audience, geography, covenant era, literary setting).")
    var context: String

    @Guide(description: "Orthodox theological reflection that flows from the passage and references its canonical placement (Old / New Testament, Apocrypha, Book of Enoch).")
    var theology: String

    @Guide(description: "Pastoral application that gently invites today’s reader to respond—prayer, practice, encouragement, or repentance.")
    var application: String

    @Guide(description: "Original-language or literary insights (Hebrew, Greek, structure, motifs, key terms) that illuminate the passage.")
    var literary: String

    @Guide(description: "Historical timeline and authorship notes (who wrote it, approximate date, canonical status, audience, major events).")
    var history: String
}
#endif
