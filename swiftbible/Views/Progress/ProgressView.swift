//
//  ProgressView.swift
//  swiftbible
//

import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var context

    @State private var currentStreak: Int = 0
    @State private var longestStreak: Int = 0
    @State private var freezeActive: Bool = false
    @State private var chaptersRead: Int = 0
    @State private var booksCompleted: Int = 0
    @State private var heatmap: [Date: Int] = [:]
    @State private var bookProgress: [BookProgress] = []
    @State private var earnedCount: Int = 0
    @State private var tierByTrack: [BadgeTrack: BadgeTier] = [:]
    @State private var showingGallery: Bool = false

    var body: some View {
        NavigationStack {
            scrollContent
                .navigationTitle("Progress")
                .background(Color(.systemGroupedBackground))
                .onAppear(perform: handleAppear)
                .sheet(isPresented: $showingGallery) {
                    BadgeGallerySheet()
                }
                #if DEBUG
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            ToastService.shared.enqueueDebugSample()
                        } label: {
                            Image(systemName: "party.popper.fill")
                        }
                        .accessibilityLabel("Trigger test badge toast")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            grantFreeBadge()
                        } label: {
                            Image(systemName: "gift.fill")
                        }
                        .accessibilityLabel("DEBUG: grant next badge (persists an EarnedBadge so CD_EarnedBadge syncs to CloudKit)")
                    }
                }
                #endif
        }
    }

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsGrid
                achievementsCard.padding(.horizontal)
                HeatmapCalendar(counts: heatmap, weeks: 12).padding(.horizontal)
                BookCompletionGrid(books: bookProgress).padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func handleAppear() {
        // BadgeService now enqueues toasts via ToastService, displayed by
        // ContentView's overlay. The Progress tab only needs to refresh
        // its own counters.
        BadgeService.shared.checkBadges(in: context)
        loadStats()
        AnalyticsService.shared.capture(.progressViewed, properties: [
            "current_streak": currentStreak,
            "longest_streak": longestStreak,
            "chapters_read": chaptersRead,
            "books_completed": booksCompleted,
            "freeze_active": freezeActive,
            "badges_earned": earnedCount
        ])
    }

    private var achievementsCard: some View {
        Button { showingGallery = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Achievements")
                        .font(.headline)
                    Spacer()
                    Text("\(earnedCount)/\(BadgeRegistry.all.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 12) {
                    ForEach(BadgeTrack.allCases, id: \.self) { track in
                        TierMedal(
                            track: track,
                            tier: tierByTrack[track]
                        )
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Achievements: \(earnedCount) of \(BadgeRegistry.all.count) earned. Tap to view all.")
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProgressStatCard(
                title: "Current Streak",
                value: "\(currentStreak)d",
                subtitle: freezeActive ? "Freeze in use" : nil,
                icon: "flame.fill",
                color: .orange,
                animated: currentStreak > 0
            )
            ProgressStatCard(
                title: "Longest Streak",
                value: "\(longestStreak)d",
                subtitle: nil,
                icon: "trophy.fill",
                color: .brandPeridot,
                animated: false
            )
            ProgressStatCard(
                title: "Chapters Read",
                value: "\(chaptersRead)",
                subtitle: nil,
                icon: "book.fill",
                color: .brandAccent,
                animated: false
            )
            ProgressStatCard(
                title: "Books Completed",
                value: "\(booksCompleted)/66",
                subtitle: nil,
                icon: "books.vertical.fill",
                color: .brandGold,
                animated: false
            )
        }
        .padding(.horizontal)
    }

    private func loadStats() {
        let service = ReadingStatsService.shared
        let streakInfo = service.currentStreakWithFreeze(in: context)
        currentStreak = streakInfo.streak
        freezeActive = streakInfo.freezeActive
        longestStreak = service.longestStreak(in: context)
        chaptersRead = service.totalChaptersRead(in: context)
        heatmap = service.dailyReadingCounts(forWeeks: 12, in: context)
        bookProgress = computeBookProgress()
        booksCompleted = bookProgress.filter { $0.isComplete }.count

        let badgeService = BadgeService.shared
        earnedCount = badgeService.earnedDefinitions(in: context).count
        var tiers: [BadgeTrack: BadgeTier] = [:]
        for track in BadgeTrack.allCases {
            tiers[track] = badgeService.currentTier(track: track, in: context)
        }
        tierByTrack = tiers
    }

    private func computeBookProgress() -> [BookProgress] {
        let allBooks: [(name: String, totalChapters: Int)] = CanonicalBibleBooks.all
        return allBooks.map { entry in
            let readChapters = ReadingStatsService.shared.chaptersReadInBook(entry.name, in: context)
            return BookProgress(
                name: entry.name,
                totalChapters: entry.totalChapters,
                readChapters: readChapters.count
            )
        }
    }

    #if DEBUG
    /// DEBUG-only: grants the next not-yet-earned badge and persists it, so the
    /// EarnedBadge record syncs to CloudKit (creating CD_EarnedBadge in the
    /// Development schema). Excluded from release builds.
    private func grantFreeBadge() {
        let earnedIds = Set(BadgeService.shared.earnedDefinitions(in: context).map { $0.id })
        guard let next = BadgeRegistry.all.first(where: { !earnedIds.contains($0.id) }) else { return }
        context.insert(EarnedBadge(badgeId: next.id, earnedAt: Date(), notified: true))
        try? context.save()
        ToastService.shared.enqueue(next)
        loadStats()
    }
    #endif
}

// MARK: - Stat Card

private struct ProgressStatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    var animated: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: animated)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Heatmap

private struct HeatmapCalendar: View {
    let counts: [Date: Int]
    let weeks: Int

    private let calendar = Calendar.current
    private let spacing: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last \(weeks) weeks")
                .font(.headline)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<weeks, id: \.self) { weekIndex in
                    VStack(spacing: spacing) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            cellForDate(weekIndex: weekIndex, dayIndex: dayIndex)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: level))
                        .frame(width: 10, height: 10)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func cellForDate(weekIndex: Int, dayIndex: Int) -> some View {
        // Right-most column = current week; left-most column = oldest week.
        let weeksAgo = weeks - 1 - weekIndex
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today) - 1 // 0-indexed Sunday
        // Total day offset from today: dayIndex represents Sun..Sat (0..6).
        // Move back to last Sunday, then forward to the desired day.
        let baseOffset = -weekday + dayIndex - (weeksAgo * 7)
        if let date = calendar.date(byAdding: .day, value: baseOffset, to: today) {
            let count = counts[calendar.startOfDay(for: date)] ?? 0
            let level = intensityLevel(for: count)
            let isFuture = date > today
            RoundedRectangle(cornerRadius: 3)
                .fill(isFuture ? Color.gray.opacity(0.08) : color(for: level))
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(accessibilityLabel(for: date, count: count, isFuture: isFuture))
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }

    private func intensityLevel(for count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1: return 1
        case 2: return 2
        case 3...4: return 3
        default: return 4
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.brandAccent.opacity(0.35)
        case 2: return Color.brandAccent.opacity(0.55)
        case 3: return Color.brandAccent.opacity(0.75)
        default: return Color.brandAccent
        }
    }

    private func accessibilityLabel(for date: Date, count: Int, isFuture: Bool) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        if isFuture { return df.string(from: date) }
        return "\(df.string(from: date)): \(count) \(count == 1 ? "session" : "sessions")"
    }
}

// MARK: - Book Completion Grid

struct BookProgress: Identifiable, Hashable {
    let name: String
    let totalChapters: Int
    let readChapters: Int

    var id: String { name }
    var percent: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(readChapters) / Double(totalChapters)
    }
    var isComplete: Bool { readChapters >= totalChapters }
}

private struct BookCompletionGrid: View {
    let books: [BookProgress]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bible Books")
                    .font(.headline)
                Spacer()
                Text("\(books.filter { $0.isComplete }.count)/\(books.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(books) { book in
                    BookProgressCell(book: book)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct BookProgressCell: View {
    let book: BookProgress

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.12))
                RoundedRectangle(cornerRadius: 6)
                    .fill(fillColor)
                    .opacity(book.percent)
                if book.isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            Text(shortName(book.name))
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.name): \(book.readChapters) of \(book.totalChapters) chapters read")
    }

    private var fillColor: Color {
        book.isComplete ? .brandPeridot : .brandAccent
    }

    private func shortName(_ name: String) -> String {
        // Drop common prefixes for compact display
        if let abbrev = CanonicalBibleBooks.shortNames[name] { return abbrev }
        return name
    }
}

// MARK: - Tier Medal

struct TierMedal: View {
    let track: BadgeTrack
    let tier: BadgeTier?

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(tier?.color ?? Color.gray.opacity(0.2))
                    .overlay(
                        Circle()
                            .stroke(tier?.accent ?? .clear, lineWidth: 1.5)
                    )
                Image(systemName: track.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tier == nil ? Color.secondary : Color.white)
            }
            .frame(width: 44, height: 44)
            Text(tier?.displayName ?? "—")
                .font(.caption2.weight(.medium))
                .foregroundStyle(tier == nil ? .secondary : .primary)
            Text(track.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.displayName) — \(tier?.displayName ?? "Not yet earned")")
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(for: [ReadingSession.self, EarnedBadge.self], inMemory: true)
}
