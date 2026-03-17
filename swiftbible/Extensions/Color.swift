//
//  Color.swift
//  swiftbible
//
//  Created on 9/10/24.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgbValue = UInt32(hex, radix: 16)
        let r = Double((rgbValue! & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue! & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue! & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexValue: String {
        let uiColor = UIColor(self)
        let components = uiColor.cgColor.components

        let red = components?[0] ?? 0
        let green = components?[1] ?? 0
        let blue = components?[2] ?? 0

        let hexString = String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))

        return hexString
    }

    // Taken from Apple's App Dev Training: https://developer.apple.com/tutorials/app-dev-training/
    /// This color is either black or white, whichever is more accessible when viewed against the scrum color.
    var accessibleFontColor: Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return isLightColor(red: red, green: green, blue: blue) ? .black : .white
    }

    private func isLightColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> Bool {
        let lightRed = red > 0.65
        let lightGreen = green > 0.65
        let lightBlue = blue > 0.65

        let lightness = [lightRed, lightGreen, lightBlue].reduce(0) { $1 ? $0 + 1 : $0 }
        return lightness >= 2
    }

    // MARK: - Brand Palette (Peridot)

    /// Yellow-green peridot — top-left of icon gradient
    static let brandPeridot = Color(red: 0.75, green: 0.85, blue: 0.0)

    /// Green midpoint of icon gradient
    static let brandGreen = Color(red: 0.2, green: 0.8, blue: 0.4)

    /// Cyan/teal — bottom-right of icon gradient
    static let brandCyan = Color(red: 0.0, green: 0.75, blue: 0.85)

    /// The full icon gradient colors array
    static let brandGradientColors: [Color] = [brandPeridot, brandGreen, brandCyan]

    /// Primary accent teal — midpoint of icon gradient, used for interactive elements
    static let brandAccent = Color(red: 0.0, green: 0.71, blue: 0.63) // #00B4A0

    /// Deep navy — launch screen and splash background
    static let brandDeepNavy = Color(red: 0.05, green: 0.07, blue: 0.15)

    /// Warm gold — book cover embossing, splash glow, devotional warmth
    static let brandGold = Color(red: 0.85, green: 0.68, blue: 0.32)

    /// Light gold tint — page glow, verse text accent
    static let brandGoldLight = Color(red: 1.0, green: 0.93, blue: 0.72)

    /// Dark leather cover
    static let brandCoverDark = Color(red: 0.18, green: 0.12, blue: 0.08)

    /// Light leather cover
    static let brandCoverLight = Color(red: 0.28, green: 0.20, blue: 0.13)

    /// Brand red — Jesus's words, ribbon bookmark, emphasis
    static let brandRed = Color(red: 0.8, green: 0.2, blue: 0.2) // #CC3333

    /// Dark red — ribbon bookmark, pressed states
    static let brandRedDark = Color(red: 0.55, green: 0.12, blue: 0.12)
}
