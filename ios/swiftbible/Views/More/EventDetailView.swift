//
//  EventDetailView.swift
//  swiftbible
//
//  Curated In-App Event view. Shows the event's day-by-day reading plan
//  using TabView's hardware-paged swipe (smooth, no jank). Up/down
//  chevrons in the toolbar duplicate the swipe affordance for users who
//  prefer explicit controls.
//
//  Presented as a sheet from MoreView (event card tap) or from the URL
//  scheme handler in ContentView (swiftbible://event/<slug>).
//

import SwiftUI
import MarkdownUI

struct EventDetailView: View {
    let event: AppEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var currentIndex: Int = 0
    @AppStorage("completedEventDayIDs") private var completedEventDayIDsRaw: String = ""
    /// In DEBUG, the Settings → Force-Show Events toggle also unlocks every
    /// day for testing. In production, only past + today's days are unlocked.
    @AppStorage("debug_forceShowEvents") private var debugForceShowEvents: Bool = false

    /// A day is unlocked if its date has arrived (today or earlier).
    /// Future days are locked to encourage daily return engagement.
    private func isUnlocked(_ day: EventReadingDay) -> Bool {
        #if DEBUG
        if debugForceShowEvents { return true }
        #endif
        return day.hasArrived
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(event.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear {
                    currentIndex = event.todayReadingIndex
                    markRead(at: currentIndex)
                }
                .onChange(of: currentIndex) { _, newValue in
                    markRead(at: newValue)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if event.readingPlan.isEmpty {
            ContentUnavailableView(
                "No Reading Plan",
                systemImage: "book.closed",
                description: Text("This event doesn't have a daily reading plan yet.")
            )
        } else {
            TabView(selection: $currentIndex) {
                ForEach(Array(event.readingPlan.enumerated()), id: \.offset) { idx, day in
                    EventDayPage(
                        day: day,
                        dayNumber: idx + 1,
                        totalDays: event.readingPlan.count,
                        accent: event.accent,
                        iconName: event.iconName,
                        isUnlocked: isUnlocked(day),
                        onOpenInBible: { openInBible(day: day) }
                    )
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 18) {
                Button {
                    if currentIndex > 0 { currentIndex -= 1 }
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(currentIndex == 0)

                Button {
                    if currentIndex < event.readingPlan.count - 1 { currentIndex += 1 }
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(currentIndex >= event.readingPlan.count - 1)
            }
            .foregroundStyle(event.accent.color)
        }
    }

    private func openInBible(day: EventReadingDay) {
        dismiss()
        // Tiny delay so the sheet finishes dismissing before navigation triggers.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            appViewModel.navigateToVerse(
                bookName: day.passage.book,
                chapterNumber: day.passage.chapter,
                verseNumber: day.passage.startVerse
            )
        }
    }

    /// Marks a reading day complete once the user lands on it (if unlocked),
    /// then re-checks badges so finishing every day unlocks the event
    /// collectible. Idempotent — a day is only recorded once.
    private func markRead(at index: Int) {
        guard event.readingPlan.indices.contains(index) else { return }
        let day = event.readingPlan[index]
        guard isUnlocked(day) else { return }
        var ids = Set(completedEventDayIDsRaw.split(separator: ",").map(String.init))
        guard !ids.contains(day.id) else { return }
        ids.insert(day.id)
        completedEventDayIDsRaw = ids.sorted().joined(separator: ",")
        BadgeService.shared.checkBadges(in: modelContext)
    }
}

private struct EventDayPage: View {
    @AppStorage("showJesusWordsInRed") private var showJesusWordsInRed: Bool = true
    let day: EventReadingDay
    let dayNumber: Int
    let totalDays: Int
    let accent: AppEventAccent
    let iconName: String
    let isUnlocked: Bool
    let onOpenInBible: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                title
                passagePill
                Divider()
                if isUnlocked {
                    reflection
                    openInBibleButton
                } else {
                    lockedPlaceholder
                }
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 60)   // breathing room above page indicator
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
            Text("DAY \(dayNumber) OF \(totalDays)")
                .font(.system(size: 11, weight: .bold, design: .serif))
                .tracking(2)
            Text("·")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(day.dateLabel)
                .font(.system(size: 11, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(accent.color)
    }

    private var title: some View {
        Text(day.theme)
            .font(.system(size: 28, weight: .black, design: .serif))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var passagePill: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(day.passage.displayLabel)
                .font(.system(size: 15, weight: .semibold, design: .serif))
        }
        .foregroundStyle(accent.color)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            Capsule().fill(accent.color.opacity(0.12))
        )
    }

    private var reflection: some View {
        // Reflections may contain Jesus blockquotes marked `> [J] "..." (v.5)`.
        // Split-render so those lines appear in red (per the app's existing
        // showJesusWordsInRed convention) while other markdown stays themed.
        VStack(alignment: .leading, spacing: 10) {
            ForEach(reflectionSegments) { segment in
                segmentView(segment)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var reflectionSegments: [ReflectionSegment] {
        ReflectionSegment.parse(day.reflection)
    }

    @ViewBuilder
    private func segmentView(_ segment: ReflectionSegment) -> some View {
        switch segment.kind {
        case .markdown:
            Markdown(segment.text)
                .markdownTheme(.eventReflection)
        case .jesusBlockquote:
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(jesusBarColor)
                    .frame(width: 3)
                Text(LocalizedStringKey(segment.text))
                    .font(.system(size: 16))
                    .italic()
                    .foregroundStyle(jesusTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }

    private var jesusTextColor: Color {
        showJesusWordsInRed ? .brandRed : .secondary
    }

    private var jesusBarColor: Color {
        showJesusWordsInRed ? .brandRed : accent.color.opacity(0.7)
    }

    private var openInBibleButton: some View {
        Button(action: onOpenInBible) {
            HStack {
                Image(systemName: "arrow.up.right.square.fill")
                Text("Read \(day.passage.displayLabel) in Bible")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accent.color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private var lockedPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(accent.color.opacity(0.7))
                .padding(.top, 28)

            Text(unlocksLabel)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Each day's reading unlocks on its date — come back \(comeBackLabel) to continue the plan.")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.top, 12)
    }

    private var unlocksLabel: String {
        let days = day.daysUntil
        if days == 1 { return "Unlocks tomorrow" }
        if days <= 7 { return "Unlocks in \(days) days" }
        return "Unlocks \(day.dateLabel)"
    }

    private var comeBackLabel: String {
        day.daysUntil == 1 ? "tomorrow" : "on \(day.dateLabel)"
    }
}

// MARK: - Reflection segment parser
//
// A reflection can interleave normal markdown with Jesus-blockquote lines:
//
//     Some intro text.
//
//     > [J] "Ye shall be baptized with the Holy Ghost not many days hence." (v.5)
//
//     More commentary.
//
// We split the source on `> [J] ` lines so we can render those in red letters
// (matching the app's showJesusWordsInRed convention) while leaving the rest
// to MarkdownUI's blockquote/paragraph styling.

private struct ReflectionSegment: Identifiable {
    enum Kind { case markdown, jesusBlockquote }
    let id = UUID()
    let kind: Kind
    let text: String

    static func parse(_ source: String) -> [ReflectionSegment] {
        let lines = source.components(separatedBy: "\n")
        var segments: [ReflectionSegment] = []
        var buffer: [String] = []

        func flushMarkdown() {
            let joined = buffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                segments.append(.init(kind: .markdown, text: joined))
            }
            buffer.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("> [J] ") {
                flushMarkdown()
                let jesusContent = String(trimmed.dropFirst("> [J] ".count))
                segments.append(.init(kind: .jesusBlockquote, text: jesusContent))
            } else {
                buffer.append(line)
            }
        }
        flushMarkdown()
        return segments
    }
}

// MARK: - Markdown theme tuned for event reflections

private extension MarkdownUI.Theme {
    /// Reading-friendly theme for the EventDetailView reflection block.
    /// Slightly larger body text + serif italics for KJV quotes work well
    /// when the reflection uses *...* around scripture lines.
    static var eventReflection: MarkdownUI.Theme {
        Theme()
            .text {
                FontSize(16)
                ForegroundColor(.primary)
            }
            .paragraph { configuration in
                configuration.label
                    .relativeLineSpacing(.em(0.25))
                    .markdownMargin(top: .em(0.5), bottom: .em(0.5))
            }
            .blockquote { configuration in
                configuration.label
                    .padding(.leading, 14)
                    .padding(.vertical, 4)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brandGold.opacity(0.7))
                            .frame(width: 3)
                    }
                    .markdownTextStyle {
                        FontStyle(.italic)
                        ForegroundColor(.secondary)
                    }
            }
            .strong {
                FontWeight(.semibold)
            }
            .emphasis {
                FontStyle(.italic)
            }
    }
}
