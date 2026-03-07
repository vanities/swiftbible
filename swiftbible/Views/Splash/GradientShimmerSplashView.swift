//
//  GradientShimmerSplashView.swift
//  swiftbible
//

import SwiftUI

struct GradientShimmerSplashView: View {
    var onFinished: () -> Void

    @State private var gradientOffset: CGFloat = -1.0
    @State private var shimmerOffset: CGFloat = -200
    @State private var contentScale: CGFloat = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var finalOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0
    @State private var showGradient: Bool = false

    private let solidColor = Color(red: 0.0, green: 0.75, blue: 0.85)

    private let gradientColors: [Color] = [
        Color(red: 0.75, green: 0.85, blue: 0.0),
        Color(red: 0.2, green: 0.8, blue: 0.4),
        Color(red: 0.0, green: 0.75, blue: 0.85)
    ]

    var body: some View {
        ZStack {
            // Background: starts as solid cyan (matching launch screen), transitions to gradient
            solidColor
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            if showGradient {
                LinearGradient(
                    colors: gradientColors + gradientColors,
                    startPoint: UnitPoint(x: gradientOffset, y: gradientOffset),
                    endPoint: UnitPoint(x: gradientOffset + 1, y: gradientOffset + 1)
                )
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .transition(.opacity)
            }

            VStack(spacing: 20) {
                // Bible icon with shimmer
                ZStack {
                    bibleIcon

                    // Shimmer highlight
                    shimmerOverlay
                        .mask(bibleIcon)
                }

                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            .scaleEffect(contentScale * pulseScale)
            .opacity(contentOpacity)
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
        // Pop in the icon and title from the plain blue background
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            contentScale = 1.0
            contentOpacity = 1.0
        }

        // Transition background to gradient
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            showGradient = true
        }

        // Background gradient flows
        withAnimation(.easeInOut(duration: 2.0).delay(0.3)) {
            gradientOffset = 1.0
        }

        // Subtle pulse after pop-in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.5)) {
            pulseScale = 1.06
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.8)) {
            pulseScale = 1.0
        }

        // First shimmer pass
        withAnimation(.easeInOut(duration: 0.7).delay(0.7)) {
            shimmerOffset = 200
        }

        // Reset and second shimmer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.6)) {
                shimmerOffset = 200
            }
        }

        // Fade out
        withAnimation(.easeIn(duration: 0.4).delay(2.0)) {
            finalOpacity = 0
            backgroundOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            onFinished()
        }
    }
}
