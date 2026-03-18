//
//  AppIconOption.swift
//  swiftbible
//

import Foundation

enum AppIconOption: String, CaseIterable, Identifiable, Hashable {
    // Themed
    case automatic
    case classic
    case ivory
    case rose
    case ruby
    case ocean
    case midnight
    case sage
    case lavender
    // Cool
    case sunset
    case aurora
    case ember
    case frost
    case neon
    case copper
    case storm
    case blossom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Default"
        case .classic: "Classic"
        case .ivory: "Ivory"
        case .rose: "Rose"
        case .ruby: "Ruby"
        case .ocean: "Ocean"
        case .midnight: "Midnight"
        case .sage: "Sage"
        case .lavender: "Lavender"
        case .sunset: "Sunset"
        case .aurora: "Aurora"
        case .ember: "Ember"
        case .frost: "Frost"
        case .neon: "Neon"
        case .copper: "Copper"
        case .storm: "Storm"
        case .blossom: "Blossom"
        }
    }

    var subtitle: String {
        switch self {
        case .automatic: "Original peridot gradient"
        case .classic: "Rich brown leather"
        case .ivory: "Clean cream & dark accents"
        case .rose: "Soft pink to mauve"
        case .ruby: "Deep crimson"
        case .ocean: "Calm sea blues"
        case .midnight: "Deep navy"
        case .sage: "Earthy muted green"
        case .lavender: "Soft purple"
        case .sunset: "Orange through pink to purple"
        case .aurora: "Northern lights shimmer"
        case .ember: "Smoldering coals"
        case .frost: "Icy arctic blue"
        case .neon: "Electric pink & cyan"
        case .copper: "Burnished metal"
        case .storm: "Thundercloud with blue"
        case .blossom: "Cherry blossom pink"
        }
    }

    /// The value passed to `setAlternateIconName`. nil = default.
    var iconName: String? {
        switch self {
        case .automatic: nil
        default: "AppIcon-\(rawValue.capitalized)"
        }
    }

    /// Preview image name — bundled as a resource
    var previewAsset: String {
        switch self {
        case .automatic: "Icon-Light-1024x1024"
        default: "Icon-\(rawValue.capitalized)1024x1024"
        }
    }
}
