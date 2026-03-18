//
//  ReadingStatsView.swift
//  swiftbible
//

import SwiftUI
import SwiftData

struct ReadingStatsView: View {
    @Environment(\.modelContext) private var context

    @State private var chaptersRead = 0
    @State private var streak = 0
    @State private var longestStreak = 0
    @State private var readingTime: TimeInterval = 0
    @State private var weekSessions: [ReadingSession] = []
    @State private var recentSessions: [ReadingSession] = []

    var body: some View {
        List {
            Section {
                statsGrid
            }

            Section("This Week") {
                weekActivity
            }

            Section("Recent Reading") {
                recentList
            }
        }
        .navigationTitle("Reading Stats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadStats()
        }
    }

    private func loadStats() {
        let service = ReadingStatsService.shared
        chaptersRead = service.totalChaptersRead(in: context)
        streak = service.currentStreak(in: context)
        longestStreak = service.longestStreak(in: context)
        readingTime = service.totalReadingTime(in: context)
        weekSessions = service.sessionsThisWeek(in: context)
        recentSessions = service.recentSessions(in: context)
    }

    @ViewBuilder
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Chapters Read",
                value: "\(chaptersRead)",
                icon: "book.fill",
                color: .brandAccent
            )
            StatCard(
                title: "Current Streak",
                value: "\(streak)d",
                icon: "flame.fill",
                color: .orange
            )
            StatCard(
                title: "Time Reading",
                value: formatDuration(readingTime),
                icon: "clock.fill",
                color: .brandGold
            )
            StatCard(
                title: "Longest Streak",
                value: "\(longestStreak)d",
                icon: "trophy.fill",
                color: .brandPeridot
            )
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var weekActivity: some View {
        if weekSessions.isEmpty {
            Text("No reading this week yet")
                .foregroundStyle(.secondary)
        } else {
            let dayTotals = weekDayTotals(from: weekSessions)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dayTotals, id: \.day) { entry in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.minutes > 0 ? Color.brandAccent : Color.gray.opacity(0.2))
                            .frame(height: max(4, CGFloat(entry.minutes) * 2))
                        Text(entry.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 80)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var recentList: some View {
        if recentSessions.isEmpty {
            Text("Start reading to see your history")
                .foregroundStyle(.secondary)
        } else {
            ForEach(recentSessions, id: \.startedAt) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(session.bookName) \(session.chapterNumber)")
                            .font(.subheadline)
                        Text(session.startedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(formatDuration(session.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private struct DayEntry {
        let day: Int
        let label: String
        let minutes: Int
    }

    private func weekDayTotals(from sessions: [ReadingSession]) -> [DayEntry] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let total = sessions
                .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                .reduce(0.0) { $0 + $1.duration }

            let label = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
            return DayEntry(day: offset, label: label, minutes: Int(total / 60))
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        ReadingStatsView()
    }
}
