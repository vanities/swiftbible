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
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, macCatalyst 26.0, visionOS 2.0, *)
@MainActor
private final class AppleFoundationModelServiceImplementation {
    static let shared = AppleFoundationModelServiceImplementation()

    private let model: SystemLanguageModel
    private let session: LanguageModelSession
    private let generationOptions: GenerationOptions

    private init(model: SystemLanguageModel = .default) {
        self.model = model
        self.session = LanguageModelSession(
            model: model,
            instructions: AppleFoundationModelService.instructions
        )
        self.generationOptions = GenerationOptions(
            sampling: nil,
            temperature: 0.8,
            maximumResponseTokens: 700
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
                        generating: VerseExplanationGeneration.self,
                        options: generationOptions
                    )

                    var lastExplanation = ""

                    // partial is the snapshot: properties are optional as the response streams.
                    for try await partial in stream {
                        guard let explanation = partial.content.explanation else { continue }
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
@Generable
private struct VerseExplanationGeneration {
    @Guide(description: "A warm, historically grounded VERY DETAILED multi-paragraph commentary that blends context, theological insight, and gentle application.")
    var explanation: String
}
#endif
