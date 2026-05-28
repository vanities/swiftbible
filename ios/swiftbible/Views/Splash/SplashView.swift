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
    @State private var splashFinished = false

    var body: some View {
        ZStack {
            ContentView(splashFinished: splashFinished)

            if showSplash {
                splashContent
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: showSplash)
    }

    private func finishSplash() {
        showSplash = false
        splashFinished = true
    }

    @ViewBuilder
    private var splashContent: some View {
        switch style {
        case .bookOpening:
            BookOpeningSplashView {
                finishSplash()
            }
        case .glowScale:
            GlowScaleSplashView {
                finishSplash()
            }
        case .gradientShimmer:
            GradientShimmerSplashView {
                finishSplash()
            }
        case .particleCross:
            ParticleCrossSplashView {
                finishSplash()
            }
        }
    }
}
