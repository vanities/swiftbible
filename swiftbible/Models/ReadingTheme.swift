//
//  ReadingTheme.swift
//  swiftbible
//

import SwiftUI

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
}
