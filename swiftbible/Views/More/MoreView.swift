//
//  MoreView.swift
//  swiftbible
//
//  Hub landing for the "More" tab. A small set of distinctive cards
//  surfacing content (History), the user's library, reading stats,
//  and settings — without looking like a settings page itself.
//

import SwiftUI

struct MoreView: View {
    @Binding var selectedTab: Tabs
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    historyHero
                    librarySection
                    statsCard
                    settingsCard
                    aboutFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Manuscript palette helpers (local to keep MoreView self-contained)

    private var parchmentInk: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.92, blue: 0.85)
            : Color(red: 0.18, green: 0.13, blue: 0.10)
    }

    private var parchmentMutedInk: Color {
        colorScheme == .dark
            ? Color(red: 0.78, green: 0.74, blue: 0.66)
            : Color(red: 0.40, green: 0.32, blue: 0.24)
    }

    private var parchmentSurface: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.10, blue: 0.07)
            : Color(red: 0.965, green: 0.94, blue: 0.88)
    }

    // MARK: - History hero

    private var historyHero: some View {
        NavigationLink(destination: HistoryView()) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Rectangle()
                        .frame(width: 16, height: 1)
                        .foregroundStyle(Color.brandGold.opacity(0.85))
                    Text("LEARN")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(2.5)
                        .foregroundStyle(Color.brandGold)
                    Rectangle()
                        .frame(width: 16, height: 1)
                        .foregroundStyle(Color.brandGold.opacity(0.85))
                    Spacer()
                    Image(systemName: "scroll.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.brandGold.opacity(0.9))
                }

                Text("History of the\nChristian Church")
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(parchmentInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Two thousand years — from the patriarchs to today, in 29 articles.")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundStyle(parchmentMutedInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(Color.brandGold.opacity(0.32))
                    .padding(.top, 4)

                HStack {
                    Text("9 SECTIONS · 29 ARTICLES")
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .tracking(2)
                        .foregroundStyle(parchmentMutedInk)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.brandGold)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(heroBackground)
        }
        .buttonStyle(.plain)
    }

    private var heroBackground: some View {
        ZStack {
            parchmentSurface
            RadialGradient(
                colors: colorScheme == .dark
                    ? [Color.brandGold.opacity(0.12), .clear]
                    : [Color(red: 1.0, green: 0.93, blue: 0.72).opacity(0.55), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 320
            )
            .blendMode(colorScheme == .dark ? .screen : .multiply)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.brandGold.opacity(0.30), lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.06),
                radius: 8, x: 0, y: 3)
    }

    // MARK: - Library row

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR LIBRARY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .padding(.top, 2)

            HStack(spacing: 10) {
                libraryCard(
                    title: "Notes",
                    icon: "note.text",
                    tint: .brandAccent,
                    destination: AnyView(SeeSavedNotesView(selectedTab: $selectedTab))
                )
                libraryCard(
                    title: "Highlights",
                    icon: "highlighter",
                    tint: .brandGold,
                    destination: AnyView(SeeHighlightsView(selectedTab: $selectedTab))
                )
                libraryCard(
                    title: "Devotionals",
                    icon: "heart.circle.fill",
                    tint: .brandRed,
                    destination: AnyView(SavedDevotionalsListView())
                )
            }
        }
    }

    private func libraryCard(
        title: String,
        icon: String,
        tint: Color,
        destination: AnyView
    ) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reading stats card

    private var statsCard: some View {
        NavigationLink(destination: ReadingStatsView()) {
            cardRow(
                icon: "chart.bar.fill",
                tint: .brandGreen,
                title: "Reading Stats",
                subtitle: "Streaks, verses, and time spent reading"
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        NavigationLink(destination: SettingsView(selectedTab: $selectedTab)) {
            cardRow(
                icon: "gearshape.fill",
                tint: .brandAccent,
                title: "Settings",
                subtitle: "Translations, fonts, notifications, and more"
            )
        }
        .buttonStyle(.plain)
    }

    private func cardRow(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - About footer

    private var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("swiftbible")
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundStyle(.secondary)
            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                Text("v\(version)")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }
}
