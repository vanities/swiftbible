//
//  ParchmentBackground.swift
//  swiftbible
//
//  Background modifier giving History views a warm cream / dark leather
//  feel with a soft radial glow. Distinct from the Bible reading surface,
//  signaling "different mode" via Von Restorff visual contrast.
//

import SwiftUI

struct ParchmentBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                base
                radialGlow
                edgeVignette
            }
            .ignoresSafeArea()
        }
    }

    private var base: some View {
        Group {
            if colorScheme == .dark {
                Color.brandCoverDark
            } else {
                Color(red: 0.965, green: 0.94, blue: 0.88)
            }
        }
    }

    private var radialGlow: some View {
        RadialGradient(
            colors: colorScheme == .dark
                ? [Color.brandGold.opacity(0.10), .clear]
                : [Color.brandGoldLight.opacity(0.55), .clear],
            center: .top,
            startRadius: 20,
            endRadius: 600
        )
        .blendMode(colorScheme == .dark ? .screen : .multiply)
        .allowsHitTesting(false)
    }

    private var edgeVignette: some View {
        RadialGradient(
            colors: colorScheme == .dark
                ? [.clear, Color.black.opacity(0.35)]
                : [.clear, Color.brandCoverDark.opacity(0.10)],
            center: .center,
            startRadius: 320,
            endRadius: 800
        )
        .allowsHitTesting(false)
    }
}

extension View {
    func parchmentBackground() -> some View {
        modifier(ParchmentBackground())
    }
}

// MARK: - Manuscript palette helpers

enum ManuscriptPalette {
    static func ink(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.95, green: 0.92, blue: 0.85)
            : Color(red: 0.18, green: 0.13, blue: 0.10)
    }

    static func mutedInk(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.78, green: 0.74, blue: 0.66)
            : Color(red: 0.40, green: 0.32, blue: 0.24)
    }

    static func cardSurface(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.04)
            : Color.white.opacity(0.55)
    }

    static func cardBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.brandGold.opacity(0.20)
            : Color.brandCoverDark.opacity(0.12)
    }

    static let accent = Color.brandGold
    static let accentDeep = Color.brandRedDark
}
