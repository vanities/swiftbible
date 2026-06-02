//
//  DonorPerksView.swift
//  swiftbible
//

import SwiftUI

struct DonorPerksView: View {
    @AppStorage("customAccentColor") private var customAccentHex: String = ""
    @AppStorage("readingTheme") private var readingThemeRaw: String = ReadingTheme.system.rawValue
    @AppStorage("selectedAppIcon") private var selectedIconRaw: String = AppIconOption.automatic.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var accentColor = Color.brandAccent

    private var readingTheme: ReadingTheme {
        ReadingTheme(rawValue: readingThemeRaw) ?? .system
    }

    private var selectedIcon: AppIconOption {
        AppIconOption(rawValue: selectedIconRaw) ?? .automatic
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Thank You", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Text("Your donation helps keep SwiftBible online and free for everyone. Here are some perks as a thank you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            .readingThemeCardRow(readingTheme, colorScheme: colorScheme)

            Section(
                header: Text("Custom Accent Color"),
                footer: Text("Changes the color of toggles, links, and active tabs throughout the app.")
            ) {
                ColorPicker("Accent Color", selection: $accentColor, supportsOpacity: false)

                if !customAccentHex.isEmpty {
                    Button("Reset to Default") {
                        accentColor = .brandAccent
                        customAccentHex = ""
                    }
                    .foregroundStyle(.red)
                }
            }
            .readingThemeCardRow(readingTheme, colorScheme: colorScheme)

            Section(
                header: Text("Reading Theme"),
                footer: Text("Customize the look of the reading view.")
            ) {
                Picker("Theme", selection: $readingThemeRaw) {
                    ForEach(ReadingTheme.allCases) { theme in
                        Label(theme.displayName, systemImage: theme.icon)
                            .tag(theme.rawValue)
                    }
                }
                .onChange(of: readingThemeRaw) {
                    AnalyticsService.shared.capture(.readingThemeChanged, properties: [
                        "theme": readingThemeRaw
                    ])
                }

                // Theme preview
                if readingTheme.isCustom {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(readingTheme.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(readingTheme.backgroundColor(for: colorScheme))
                            .frame(height: 50)
                            .overlay(
                                Text("In the beginning God created the heaven and the earth.")
                                    .font(.subheadline)
                                    .foregroundStyle(readingTheme.textColor(for: colorScheme))
                                    .padding(.horizontal, 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .readingThemeCardRow(readingTheme, colorScheme: colorScheme)

            Section(
                header: Text("App Icon"),
                footer: Text("Choose your preferred app icon style.")
            ) {
                NavigationLink {
                    AppIconPickerView()
                } label: {
                    HStack {
                        Label("App Icon", systemImage: "app.fill")
                        Spacer()
                        Text(selectedIcon.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .readingThemeCardRow(readingTheme, colorScheme: colorScheme)

        }
        .readingThemeScreen(readingTheme, colorScheme: colorScheme)
        .navigationTitle("Donor Perks")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !customAccentHex.isEmpty {
                accentColor = Color(hex: customAccentHex)
            }
        }
        .onChange(of: accentColor) {
            customAccentHex = accentColor.hexValue
        }
    }
}

#Preview {
    NavigationStack {
        DonorPerksView()
    }
}
