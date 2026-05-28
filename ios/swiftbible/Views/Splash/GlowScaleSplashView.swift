//
//  GlowScaleSplashView.swift
//  swiftbible
//

import SwiftUI

struct GlowScaleSplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var iconOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.6
    @State private var glowRadius: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 10
    @State private var finalScale: CGFloat = 1.0
    @State private var finalOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0

    private let gradientColors: [Color] = Color.brandGradientColors

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            // Glow rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 150
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200 + CGFloat(index) * 60)
                    .scaleEffect(ringScale + CGFloat(index) * 0.1)
                    .opacity(ringOpacity)
            }

            VStack(spacing: 20) {
                // Bible icon with glow
                ZStack {
                    // Golden glow behind icon
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                        .blur(radius: glowRadius)
                        .opacity(glowOpacity)

                    // Main icon
                    bibleIcon
                        .opacity(iconOpacity)
                        .scaleEffect(iconScale)
                }
                .scaleEffect(finalScale)
                .opacity(finalOpacity)

                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                    .scaleEffect(finalScale > 1.5 ? finalScale * 0.6 : 1.0)
            }
        }
        .onAppear {
            animate()
        }
    }

    private var bibleIcon: some View {
        ZStack {
            // Book shape
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
                .frame(width: 100, height: 130)

            // Cross
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white)
                    .frame(width: 4, height: 35)
                Rectangle()
                    .fill(.white)
                    .frame(width: 24, height: 4)
                Rectangle()
                    .fill(.white)
                    .frame(width: 4, height: 22)
            }

            // Book spine detail
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(white: 0.3), lineWidth: 1.5)
                .frame(width: 100, height: 130)

            // Bookmark tab
            Path { path in
                path.move(to: CGPoint(x: 35, y: 130))
                path.addLine(to: CGPoint(x: 35, y: 142))
                path.addLine(to: CGPoint(x: 42, y: 136))
                path.addLine(to: CGPoint(x: 49, y: 142))
                path.addLine(to: CGPoint(x: 49, y: 130))
            }
            .fill(Color(white: 0.15))
            .offset(x: -8, y: 3)
        }
    }

    private func animate() {
        if reduceMotion {
            iconOpacity = 1
            iconScale = 1.0
            titleOpacity = 1
            titleOffset = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                finalOpacity = 0
                backgroundOpacity = 0
                onFinished()
            }
            return
        }

        // Icon fades in and scales up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconOpacity = 1
            iconScale = 1.0
        }

        // Glow radiates outward
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            glowRadius = 30
            glowOpacity = 0.6
        }

        // Rings expand
        withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
            ringScale = 1.2
            ringOpacity = 0.5
        }

        // Title appears
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            titleOpacity = 1
            titleOffset = 0
        }

        // Rings fade
        withAnimation(.easeIn(duration: 0.4).delay(1.2)) {
            ringOpacity = 0
        }

        // Scale up and fade out
        withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
            finalScale = 3.0
            finalOpacity = 0
            titleOpacity = 0
            backgroundOpacity = 0
            glowOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onFinished()
        }
    }
}
