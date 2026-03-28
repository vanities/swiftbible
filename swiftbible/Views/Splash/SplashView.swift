//
//  SplashView.swift
//  swiftbible
//

import SwiftUI

enum SplashStyle: String, CaseIterable {
    case bookOpening
    case glowScale
    case gradientShimmer
    case particleCross
}

struct SplashView: View {
    // Change this to preview different styles
    var style: SplashStyle = .bookOpening

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                splashContent
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: showSplash)
    }

    @ViewBuilder
    private var splashContent: some View {
        switch style {
        case .bookOpening:
            BookOpeningSplashView {
                showSplash = false
            }
        case .glowScale:
            GlowScaleSplashView {
                showSplash = false
            }
        case .gradientShimmer:
            GradientShimmerSplashView {
                showSplash = false
            }
        case .particleCross:
            ParticleCrossSplashView {
                showSplash = false
            }
        }
    }
}
