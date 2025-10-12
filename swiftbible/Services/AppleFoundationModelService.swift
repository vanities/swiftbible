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

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence is currently unavailable: \(reason)."
        }
    }
}

@MainActor
final class AppleFoundationModelService {
    static let shared = AppleFoundationModelService()

    fileprivate static let instructions = "You are a trusted pastoral Bible commentary assistant. Offer historically grounded, theologically orthodox insights that respect the passage's canonical context. Write warmly but avoid personal greetings or letters."

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
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            return AppleFoundationModelServiceImplementation.shared.availabilityStatus
        }
        return .unsupportedOS
    }

    func streamExplanation(for request: VerseExplanationRequest) -> AsyncThrowingStream<String, Error> {
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

    func resetSession() {
        if #available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *) {
            AppleFoundationModelServiceImplementation.shared.resetSession()
        }
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
            maximumResponseTokens: 900
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
                    let stream = session.streamResponse(
                        to: request.userPrompt,
                        generating: VerseCommentary.self,
                        options: generationOptions
                    )

                    var lastExplanation = ""

                    // partial is the snapshot: properties are optional as the response streams.
                    for try await partial in stream {
                        let commentary = partial.content
                        #if DEBUG
                        print("[AppleFoundationModelService] commentary snapshot: \(commentary)")
                        #endif
                        let explanation = Self.render(commentary: commentary)
                        #if DEBUG
                        print("[AppleFoundationModelService] snapshot explanation: \(String(reflecting: explanation))")
                        #endif
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

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
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
