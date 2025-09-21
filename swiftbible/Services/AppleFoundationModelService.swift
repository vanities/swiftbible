//
//  AppleFoundationModelService.swift
//  swiftbible
//
//  Created by OpenAI.
//

import Foundation
import FoundationModels

enum AppleFoundationModelServiceError: LocalizedError {
    case modelUnavailable(reason: String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "Apple Intelligence is currently unavailable: \(reason)."
        }
    }
}

@Generable
private struct VerseExplanationGeneration {
    @Guide(description: "A warm, pastoral explanation of the requested Bible passage.")
    var explanation: String
}

@MainActor
final class AppleFoundationModelService {
    static let shared = AppleFoundationModelService()

    private let session: LanguageModelSession
    private let model: SystemLanguageModel

    private init(
        model: SystemLanguageModel = .default,
        instructions: String = "You are a trusted pastoral Bible commentary assistant who provides historically grounded, Christ-centered explanations of Scripture."
    ) {
        self.model = model
        self.session = LanguageModelSession(
            model: model,
            instructions: instructions
        )
    }

    var availability: SystemLanguageModel.Availability { model.availability }

    var isResponding: Bool { session.isResponding }

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
                        generating: VerseExplanationGeneration.self
                    )

                    var lastExplanation = ""

                    for try await partial in stream {
                        guard let explanation = partial.explanation else { continue }
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
