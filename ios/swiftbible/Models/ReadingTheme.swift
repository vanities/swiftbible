//
//  ReadingTheme.swift
//  swiftbible
//

import SwiftUI
import MarkdownUI

enum ReadingTheme: String, CaseIterable, Identifiable {
    case system
    case sepia
    case trueBlack
    case highContrast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .sepia: "Warm Sepia"
        case .trueBlack: "True Black"
        case .highContrast: "High Contrast"
        }
    }

    var subtitle: String {
        switch self {
        case .system: "Default system appearance"
        case .sepia: "Warm, easy on the eyes"
        case .trueBlack: "Pure black for OLED displays"
        case .highContrast: "Maximum readability"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .sepia: "sun.max"
        case .trueBlack: "moon.fill"
        case .highContrast: "textformat.size.larger"
        }
    }

    /// Returns the background color, adapting to the current color scheme.
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return .clear
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.16, green: 0.12, blue: 0.08)   // dark warm brown
                : Color(red: 0.96, green: 0.90, blue: 0.78)   // warm cream
        case .trueBlack:
            return .black
        case .highContrast:
            return colorScheme == .dark ? .black : .white
        }
    }

    /// Returns the primary text color, adapting to the current color scheme.
    func textColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return .primary
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.90, green: 0.82, blue: 0.70)   // warm light text
                : Color(red: 0.36, green: 0.27, blue: 0.21)   // dark brown text
        case .trueBlack:
            return Color(red: 0.88, green: 0.88, blue: 0.88)
        case .highContrast:
            return colorScheme == .dark ? .white : .black
        }
    }

    /// Returns the secondary text color (verse numbers, etc.)
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .system:
            return .gray
        case .sepia:
            return colorScheme == .dark
                ? Color(red: 0.65, green: 0.55, blue: 0.45)
                : Color(red: 0.50, green: 0.42, blue: 0.35)
        case .trueBlack:
            return Color(red: 0.55, green: 0.55, blue: 0.55)
        case .highContrast:
            return colorScheme == .dark
                ? Color(red: 0.7, green: 0.7, blue: 0.7)
                : Color(red: 0.3, green: 0.3, blue: 0.3)
        }
    }

    var isCustom: Bool {
        self != .system
    }

    /// The color scheme this theme must render in, or `nil` to follow the system.
    /// True Black forces a black background even in light mode, so it has to run
    /// in dark mode — otherwise default `.primary`/`.secondary` text stays dark and
    /// disappears against the black. Sepia and High Contrast already adapt their
    /// background to the system scheme, so they follow it.
    var forcedColorScheme: ColorScheme? {
        switch self {
        case .trueBlack: return .dark
        default: return nil
        }
    }
}

// MARK: - Reading presentation helpers
//
// Shared so every *reading* surface (Bible chapters, daily + saved
// devotionals, the book list) honors the same font + ReadingTheme, instead of
// the theme/font only reaching chapter reading. Lives here (not a standalone
// file) because the main app target uses explicit file references, not a
// filesystem-synchronized group — a new file would need a project.pbxproj edit.

extension MarkdownUI.Theme {
    /// MarkdownUI theme for devotional content: applies the user's chosen font
    /// and the active ReadingTheme's text color while keeping `Theme.basic`'s
    /// block structure. Headings stay body-size + bold to match the existing
    /// daily devotional look.
    static func swiftBibleReading(
        fontName: String,
        fontSize: Int,
        reading: ReadingTheme,
        colorScheme: ColorScheme
    ) -> MarkdownUI.Theme {
        let textColor: Color = reading.isCustom ? reading.textColor(for: colorScheme) : .primary
        let secondaryColor: Color = reading.isCustom ? reading.secondaryTextColor(for: colorScheme) : .secondary

        return Theme.basic
            .text {
                FontFamily(.custom(fontName))
                FontSize(CGFloat(fontSize))
                ForegroundColor(textColor)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: .em(1), bottom: .em(1))
                    .markdownTextStyle {
                        FontFamily(.custom(fontName))
                        FontWeight(.bold)
                        FontSize(.em(1))
                        ForegroundColor(textColor)
                    }
            }
            .blockquote { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom(fontName))
                        ForegroundColor(secondaryColor)
                    }
            }
    }
}

extension View {
    /// Paints a reading surface with the active ReadingTheme's background.
    /// A no-op (clear) for the default `.system` theme, so the default
    /// appearance is unchanged.
    @ViewBuilder
    func readingThemeBackground(_ reading: ReadingTheme, colorScheme: ColorScheme) -> some View {
        background(reading.isCustom ? reading.backgroundColor(for: colorScheme) : Color.clear)
    }

    /// Full reading-theme treatment for a scrollable screen (List / ScrollView /
    /// Form) inside a NavigationStack: hides the default scroll background,
    /// paints the theme color under the safe areas, and tints the navigation bar
    /// to match (so the title/search area at the top isn't left un-themed).
    /// No-op for the default `.system` theme.
    @ViewBuilder
    func readingThemeScreen(_ reading: ReadingTheme, colorScheme: ColorScheme) -> some View {
        if reading.isCustom {
            let bg = reading.backgroundColor(for: colorScheme)
            self
                .scrollContentBackground(.hidden)
                .background(bg.ignoresSafeArea())
                .toolbarBackground(bg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            self
        }
    }

    /// Background-only theming for a List / Form / ScrollView whose navigation
    /// bar is already tinted globally (ContentView.applyNavBarAppearance): hides
    /// the default scroll background and paints the theme color under the safe
    /// areas. Single-type so it's cheap to type-check. No-op for `.system`.
    func readingThemeContentBackground(_ reading: ReadingTheme, colorScheme: ColorScheme) -> some View {
        self
            .scrollContentBackground(reading.isCustom ? .hidden : .automatic)
            .background(
                (reading.isCustom ? reading.backgroundColor(for: colorScheme) : Color.clear)
                    .ignoresSafeArea()
            )
    }

    /// Clears a List row's background so the themed surface shows through.
    /// Apply to each row (or Section) — `.listRowBackground` on the List itself
    /// does not propagate. No-op (default background) for the `.system` theme.
    /// High Contrast instead outlines each row so structure stays defined.
    /// Single-type (`AnyView?`) to keep large List bodies type-checkable.
    func readingThemeRow(_ reading: ReadingTheme) -> some View {
        listRowBackground(readingThemeRowBackground(reading))
    }

    /// Tints a List Section's rows to a subtle raised "card" surface on the
    /// themed background (instead of standard white grouped cells). High Contrast
    /// outlines each row instead. Apply to each Section. No-op for `.system`.
    func readingThemeCardRow(_ reading: ReadingTheme, colorScheme: ColorScheme) -> some View {
        listRowBackground(readingThemeCardRowBackground(reading, colorScheme: colorScheme))
    }

    /// Tints just the navigation bar to the theme color. For screens that
    /// already manage their own content background (e.g. a ScrollView with an
    /// explicit grouped background) so only the top bar needs matching.
    /// No-op for the default `.system` theme.
    @ViewBuilder
    func readingThemeNavBar(_ reading: ReadingTheme, colorScheme: ColorScheme) -> some View {
        if reading.isCustom {
            let bg = reading.backgroundColor(for: colorScheme)
            toolbarBackground(bg, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            self
        }
    }
}

// MARK: - Row background resolution
//
// Returned as `AnyView?` so `listRowBackground` sees one concrete type
// (nil → default cell), keeping large List bodies cheap to type-check.

/// An outlined "card" for High Contrast rows: transparent center (max text
/// contrast) with a `.primary` border that adapts (black on white / white on
/// black). Padded so adjacent rows read as separate boxes.
private func highContrastRowOutline() -> AnyView {
    AnyView(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Color.primary, lineWidth: 1.5)
            .padding(.vertical, 3)
    )
}

private func readingThemeRowBackground(_ reading: ReadingTheme) -> AnyView? {
    if reading == .highContrast {
        return highContrastRowOutline()
    } else if reading.isCustom {
        return AnyView(Color.clear)
    } else {
        return nil
    }
}

private func readingThemeCardRowBackground(_ reading: ReadingTheme, colorScheme: ColorScheme) -> AnyView? {
    if reading == .highContrast {
        return highContrastRowOutline()
    } else if reading.isCustom {
        return AnyView(reading.secondaryTextColor(for: colorScheme).opacity(0.12))
    } else {
        return nil
    }
}
