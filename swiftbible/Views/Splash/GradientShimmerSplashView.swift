//
//  GradientShimmerSplashView.swift
//  swiftbible
//

import SwiftUI

struct GradientShimmerSplashView: View {
    var onFinished: () -> Void

    @State private var gradientOffset: CGFloat = -1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var iconScale: CGFloat = 1.0
    @State private var iconOpacity: Double = 1.0
    @State private var titleOpacity: Double = 1.0
    @State private var titleOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var finalOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0

    private let gradientColors: [Color] = [
        Color(red: 0.75, green: 0.85, blue: 0.0),
        Color(red: 0.2, green: 0.8, blue: 0.4),
        Color(red: 0.0, green: 0.75, blue: 0.85)
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: gradientColors + gradientColors,
                startPoint: UnitPoint(x: gradientOffset, y: gradientOffset),
                endPoint: UnitPoint(x: gradientOffset + 1, y: gradientOffset + 1)
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            VStack(spacing: 20) {
                // Bible icon with shimmer
                ZStack {
                    bibleIcon
                        .opacity(iconOpacity)
                        .scaleEffect(iconScale)

                    // Shimmer highlight
                    shimmerOverlay
                        .mask(bibleIcon)
                        .opacity(iconOpacity)
                        .scaleEffect(iconScale)
                }

                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
            .scaleEffect(pulseScale)
            .opacity(finalOpacity)
        }
        .ignoresSafeArea()
        .onAppear {
            animate()
        }
    }

    private var bibleIcon: some View {
        ZStack {
            // Book body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
                .frame(width: 120, height: 155)

            // Cross - vertical bar
            Rectangle()
                .fill(.white)
                .frame(width: 5, height: 45)
                .offset(y: -10)

            // Cross - horizontal bar
            Rectangle()
                .fill(.white)
                .frame(width: 30, height: 5)
                .offset(y: -17)

            // Cross - lower vertical
            Rectangle()
                .fill(.white)
                .frame(width: 5, height: 28)
                .offset(y: 12)

            // Book outline
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(white: 0.3), lineWidth: 1.5)
                .frame(width: 120, height: 155)

            // Bookmark
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: 8, y: 10))
                path.addLine(to: CGPoint(x: 16, y: 16))
                path.addLine(to: CGPoint(x: 16, y: 0))
            }
            .fill(Color(white: 0.15))
            .frame(width: 16, height: 16)
            .offset(x: -20, y: 82)
        }
    }

    private var shimmerOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.5),
                        .white.opacity(0.8),
                        .white.opacity(0.5),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 60)
            .offset(x: shimmerOffset)
            .frame(width: 200, height: 200)
            .clipped()
    }

    private func animate() {
        // Spring pulse (icon+text breathe outward then settle)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
            pulseScale = 1.08
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(0.4)) {
            pulseScale = 1.0
        }

        // Background gradient flows
        withAnimation(.easeInOut(duration: 2.0).delay(0.1)) {
            gradientOffset = 1.0
        }

        // First shimmer pass
        withAnimation(.easeInOut(duration: 0.7).delay(0.5)) {
            shimmerOffset = 200
        }

        // Reset and second shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.6)) {
                shimmerOffset = 200
            }
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.4).delay(1.8)) {
            finalOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            onFinished()
        }
    }
}
