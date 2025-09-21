//
//  VerseExplanationSheet.swift
//  swiftbible
//
//  Created by OpenAI.
//

import SwiftUI
import UIKit

struct VerseExplanationSheet: View {
    let request: VerseExplanationRequest
    private let service: AppleFoundationModelService

    @Environment(\.dismiss) private var dismiss

    @State private var explanation: String = ""
    @State private var isStreaming: Bool = true
    @State private var errorMessage: String?
    @State private var streamTask: Task<Void, Never>?
    @State private var availabilityStatus: AppleFoundationModelService.AvailabilityStatus

    init(request: VerseExplanationRequest, service: AppleFoundationModelService = .shared) {
        self.request = request
        self.service = service
        _availabilityStatus = State(initialValue: service.availabilityStatus)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(request.reference)
                            .font(.headline)
                        if request.shouldDisplayTranslationBadge {
                            Text(request.translation.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                        Spacer(minLength: 0)
                    }
                    ParagraphView(
                        firstVerseNumber: request.startingVerse,
                        paragraph: request.paragraphText
                    )
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                Divider()

                Group {
                    if let errorMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .labelStyle(.titleAndIcon)
                            Button("Try Again") {
                                startStreaming(forceRestart: true)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!availabilityStatus.isReadyForGeneration)
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if explanation.isEmpty {
                                    Text("Waiting for Apple Intelligence…")
                                        .foregroundStyle(.secondary)
                                } else {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Spacer()
                                            AIGeneratedBadge(message: "This explanation was generated on device with Apple Intelligence.")
                                                .padding(.trailing, 4)
                                        }

                                        Text(explanation)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                if isStreaming && errorMessage == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Streaming explanation…")
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Explain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !explanation.isEmpty {
                        Button {
                            UIPasteboard.general.string = explanation
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .onAppear { startStreaming() }
            .onDisappear { streamTask?.cancel() }
        }
    }

    private func startStreaming(forceRestart: Bool = false) {
        if streamTask != nil && !forceRestart { return }
        streamTask?.cancel()
        explanation = ""
        errorMessage = nil

        let status = service.availabilityStatus
        availabilityStatus = status

        guard status.isReadyForGeneration else {
            isStreaming = false
            streamTask = nil
            errorMessage = status.advisoryMessage
            return
        }

        isStreaming = true

        streamTask = Task { @MainActor in
            do {
                let stream = await service.streamExplanation(for: request)
                for try await chunk in stream {
                    explanation.append(chunk)
                }
                isStreaming = false
                streamTask = nil
            } catch is CancellationError {
                streamTask = nil
                isStreaming = false
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isStreaming = false
                streamTask = nil
            }
        }
    }
}

#Preview {
    VerseExplanationSheet(
        request: VerseExplanationRequest(
            bookName: "John",
            chapter: 3,
            startingVerse: 16,
            translation: "ESV",
            paragraphText: "3:16 For God so loved the world, that he gave his only Son, that whoever believes in him should not perish but have eternal life."
        )
    )
}
