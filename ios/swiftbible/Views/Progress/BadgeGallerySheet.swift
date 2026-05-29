//
//  BadgeGallerySheet.swift
//  swiftbible
//

import SwiftUI
import SwiftData

struct BadgeGallerySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var earnedIds: Set<String> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tierLadder
                    collectibles
                    hiddenAchievements
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                refresh()
                AnalyticsService.shared.capture(.badgeGalleryViewed, properties: [
                    "earned": earnedIds.count,
                    "total": BadgeRegistry.all.count
                ])
            }
        }
    }

    private func refresh() {
        earnedIds = Set(BadgeService.shared.earnedDefinitions(in: context).map { $0.id })
    }

    // MARK: - Tier ladder

    private var tierLadder: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Tiers", subtitle: "Bronze → Diamond across \(BadgeTrack.allCases.count) tracks")

            ForEach(BadgeTrack.allCases, id: \.self) { track in
                tierRow(track: track)
            }
        }
    }

    private func tierRow(track: BadgeTrack) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: track.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(track.displayName.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ForEach(BadgeTier.allCases, id: \.self) { tier in
                    let def = BadgeRegistry.tier(track: track, tier: tier)
                    BadgeCell(
                        definition: def,
                        earned: earnedIds.contains(def.id),
                        revealed: true,
                        nameOverride: tier.displayName
                    )
                }
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Visible collectibles

    private var collectibles: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Collectibles",
                subtitle: "Read meaningful groupings end to end"
            )
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BadgeRegistry.collectibles) { def in
                    BadgeCell(definition: def, earned: earnedIds.contains(def.id), revealed: true)
                }
            }
        }
    }

    // MARK: - Hidden achievements

    private var hiddenAchievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            let earnedHidden = BadgeRegistry.hidden.filter { earnedIds.contains($0.id) }.count
            sectionHeader(
                title: "Hidden Achievements",
                subtitle: "\(earnedHidden) of \(BadgeRegistry.hidden.count) discovered"
            )
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BadgeRegistry.hidden) { def in
                    BadgeCell(
                        definition: def,
                        earned: earnedIds.contains(def.id),
                        revealed: earnedIds.contains(def.id)
                    )
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.bold())
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Badge cell

private struct BadgeCell: View {
    let definition: BadgeDefinition
    let earned: Bool
    /// For hidden badges, false until earned. Shows silhouette + "?"
    let revealed: Bool
    /// Optional shorter label — used by the tier ladder where the
    /// section header already names the track (e.g. "DEVOTIONALS"), so
    /// the cell only needs the tier ("Bronze").
    var nameOverride: String?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 60, height: 60)

                if revealed {
                    Image(systemName: definition.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(iconColor)
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(displayedName)
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(revealed ? .primary : .secondary)

            Text(revealed ? definition.description : "Keep reading to discover")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if earned {
                Text("EARNED")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(definition.tint)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(earned ? definition.tint.opacity(0.6) : .clear, lineWidth: 1.5)
        )
        .opacity(earned ? 1.0 : 0.85)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayedName: String {
        if !revealed { return "Hidden" }
        return nameOverride ?? definition.name
    }

    private var circleFill: Color {
        if !revealed { return Color.gray.opacity(0.18) }
        if earned { return definition.tint.opacity(0.85) }
        return definition.tint.opacity(0.18)
    }

    private var iconColor: Color {
        if earned { return .white }
        return definition.tint
    }

    private var accessibilityLabel: String {
        if !revealed {
            return "Hidden achievement, not yet earned"
        }
        let status = earned ? "Earned" : "Locked"
        return "\(definition.name). \(definition.description). \(status)."
    }
}

#Preview {
    BadgeGallerySheet()
        .modelContainer(for: [ReadingSession.self, EarnedBadge.self], inMemory: true)
}
