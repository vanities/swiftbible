//
//  VerseExplanationSheet.swift
//  swiftbible
//
//  Created by OpenAI.
//

import SwiftUI
import UIKit

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct VerseExplanationSheet: View {
    let request: VerseExplanationRequest

    @Environment(\.dismiss) private var dismiss

    @State private var explanation: String = ""
    @State private var isStreaming: Bool = true
    @State private var errorMessage: String?
    @State private var streamTask: Task<Void, Never>?
    @State private var availabilityStatus: AppleFoundationModelService.AvailabilityStatus = .unsupportedOS
    @State private var scrollOffset: CGFloat = 0
    @State private var showToast = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Collapsing header section
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

                        if headerScale > 0.3 {
                            ParagraphView(
                                firstVerseNumber: request.startingVerse,
                                paragraph: request.paragraphText
                            )
                            .scaleEffect(headerScale, anchor: .top)
                            .opacity(headerOpacity)
                            .padding(12 * headerScale)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12 * headerScale))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 8)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )

                    Divider()
                        .padding(.horizontal)

                    // Content section
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
                            .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                if explanation.isEmpty {
                                    Text("Waiting for Apple Intelligence…")
                                        .foregroundStyle(.secondary)
                                } else {
                                    CommentarySectionsView(
                                        sections: explanationSections(from: explanation),
                                        badgeMessage: "This explanation was generated on device with Apple Intelligence. Large language models can make mistakes, produce inaccurate information, or generate content that may not align with biblical teaching. Always verify important information and consult trusted sources."
                                    )
                                    .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }
                    }

                    if isStreaming && errorMessage == nil {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Streaming explanation…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
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
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation {
                                showToast = true
                            }
                            // Auto-dismiss after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            .onAppear { startStreaming() }
            .onDisappear {
                streamTask?.cancel()
                Task { @MainActor in
                    AppleFoundationModelService.shared.resetSession()
                }
            }
            .overlay(
                Group {
                    if showToast {
                        if #available(iOS 26.0, *) {
                            Text("Copied to clipboard")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassEffect()
                                .shadow(radius: 10)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .padding(.top, 60)
                        } else {
                            Text("Copied to clipboard")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 10)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .padding(.top, 60)
                        }
                    }
                },
                alignment: .top
            )
        }
    }

    private var headerScale: CGFloat {
        let threshold: CGFloat = 100
        let scale = max(0.3, min(1.0, 1.0 - (abs(scrollOffset) / threshold)))
        return scale
    }

    private var headerOpacity: Double {
        let threshold: CGFloat = 100
        let opacity = max(0.0, min(1.0, 1.0 - (abs(scrollOffset) / threshold)))
        return opacity
    }

    private func startStreaming(forceRestart: Bool = false) {
        if streamTask != nil && !forceRestart { return }
        streamTask?.cancel()
        explanation = ""
        errorMessage = nil

        Task { @MainActor in
            let status = AppleFoundationModelService.shared.availabilityStatus
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
                    let stream = AppleFoundationModelService.shared.streamExplanation(for: request)
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

private extension VerseExplanationSheet {
    struct CommentarySectionsView: View {
        let sections: ExplanationSections
        let badgeMessage: String

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    AIGeneratedBadge(message: badgeMessage)
                        .padding(.trailing, 4)
                }

                if let summary = sections.summary {
                    Text(summary)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(Array(zip(sections.bodySections.indices, sections.bodySections)), id: \.0) { _, section in
                    VStack(alignment: .leading, spacing: 6) {
                        if let title = section.title {
                            Text(title)
                                .font(.headline)
                        }
                        Text(section.body)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
        }
    }

    struct ExplanationBodySection {
        let title: String?
        let body: String
    }

    struct ExplanationSections {
        let summary: String?
        let bodySections: [ExplanationBodySection]
    }

    func explanationSections(from text: String) -> ExplanationSections {
        let chunks = text.split(separator: "\n\n", omittingEmptySubsequences: true)
        guard !chunks.isEmpty else { return ExplanationSections(summary: nil, bodySections: []) }

        var summary: String?
        var sections: [ExplanationBodySection] = []

        for (index, chunk) in chunks.enumerated() {
            let sectionString = String(chunk)
            if index == 0 && !sectionString.contains("\n") {
                summary = sectionString
                continue
            }

            if let newlineIndex = sectionString.firstIndex(of: "\n") {
                let title = String(sectionString[..<newlineIndex])
                let bodyStart = sectionString.index(after: newlineIndex)
                let body = String(sectionString[bodyStart...])
                sections.append(ExplanationBodySection(title: title, body: body))
            } else {
                if summary == nil {
                    summary = sectionString
                } else {
                    sections.append(ExplanationBodySection(title: nil, body: sectionString))
                }
            }
        }

        return ExplanationSections(summary: summary, bodySections: sections)
    }
}
