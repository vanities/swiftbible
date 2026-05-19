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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statsGrid

                    HeatmapCalendar(counts: heatmap, weeks: 12)
                        .padding(.horizontal)

                    BookCompletionGrid(books: bookProgress)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                loadStats()
                AnalyticsService.shared.capture(.progressViewed, properties: [
                    "current_streak": currentStreak,
                    "longest_streak": longestStreak,
                    "chapters_read": chaptersRead,
                    "books_completed": booksCompleted,
                    "freeze_active": freezeActive
                ])
            }
        }
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
    private let cellSize: CGFloat = 14
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
                }
            }

            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: level))
                        .frame(width: cellSize - 4, height: cellSize - 4)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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
                .frame(width: cellSize, height: cellSize)
                .accessibilityLabel(accessibilityLabel(for: date, count: count, isFuture: isFuture))
        } else {
            Color.clear.frame(width: cellSize, height: cellSize)
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

#Preview {
    ProgressTabView()
        .modelContainer(for: ReadingSession.self, inMemory: true)
}
