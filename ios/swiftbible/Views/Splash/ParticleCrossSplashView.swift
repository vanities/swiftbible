//
//  ParticleCrossSplashView.swift
//  swiftbible
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var startX: CGFloat
    var startY: CGFloat
    var targetX: CGFloat
    var targetY: CGFloat
    var size: CGFloat
    var color: Color
}

struct ParticleCrossSplashView: View {
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var particles: [Particle] = []
    @State private var converged = false
    @State private var crossOpacity: Double = 0
    @State private var bookOpacity: Double = 0
    @State private var bookScale: CGFloat = 0.7
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 15
    @State private var particleOpacity: Double = 1.0
    @State private var finalOpacity: Double = 1.0
    @State private var backgroundOpacity: Double = 1.0

    private let gradientColors: [Color] = Color.brandGradientColors

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)

            VStack(spacing: 20) {
                ZStack {
                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [particle.color, particle.color.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: particle.size
                                )
                            )
                            .frame(width: particle.size * 2, height: particle.size * 2)
                            .position(
                                x: converged ? particle.targetX : particle.startX,
                                y: converged ? particle.targetY : particle.startY
                            )
                    }
                    .opacity(particleOpacity)

                    // Cross that appears after convergence
                    crossShape
                        .opacity(crossOpacity)

                    // Bible outline
                    bibleOutline
                        .opacity(bookOpacity)
                        .scaleEffect(bookScale)
                }
                .frame(width: 200, height: 200)

                Text("SwiftBible")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
            }
            .opacity(finalOpacity)
        }
        .onAppear {
            generateParticles()
            animate()
        }
    }

    private var crossShape: some View {
        ZStack {
            // Vertical bar
            Rectangle()
                .fill(.white)
                .frame(width: 6, height: 50)
                .offset(y: -5)

            // Horizontal bar
            Rectangle()
                .fill(.white)
                .frame(width: 34, height: 6)
                .offset(y: -15)

            // Lower vertical
            Rectangle()
                .fill(.white)
                .frame(width: 6, height: 30)
                .offset(y: 18)
        }
    }

    private var bibleOutline: some View {
        ZStack {
            // Book shape outline
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.15))
                .frame(width: 110, height: 145)

            // Cross on book
            crossShape

            // Book stroke
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color(white: 0.3), lineWidth: 1.5)
                .frame(width: 110, height: 145)

            // Bookmark
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 14))
                path.addLine(to: CGPoint(x: 7, y: 9))
                path.addLine(to: CGPoint(x: 14, y: 14))
                path.addLine(to: CGPoint(x: 14, y: 0))
            }
            .fill(Color(white: 0.15))
            .frame(width: 14, height: 14)
            .offset(x: -18, y: 76)
        }
    }

    private func generateParticles() {
        let crossPoints = generateCrossTargetPoints()
        let colors: [Color] = [
            .white,
            Color.brandPeridot.opacity(0.9),
            Color.brandGreen.opacity(0.9),
            Color.brandCyan.opacity(0.9)
        ]

        particles = crossPoints.map { point in
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 150...300)
            return Particle(
                startX: 100 + cos(angle) * distance,
                startY: 100 + sin(angle) * distance,
                targetX: point.x,
                targetY: point.y,
                size: CGFloat.random(in: 3...7),
                color: colors.randomElement() ?? .white
            )
        }
    }

    private func generateCrossTargetPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        let centerX: CGFloat = 100
        let centerY: CGFloat = 95

        // Vertical bar of cross
        for yOff in stride(from: -25, through: 35, by: 4) {
            points.append(CGPoint(x: centerX + CGFloat.random(in: -3...3),
                                  y: centerY + CGFloat(yOff) + CGFloat.random(in: -2...2)))
        }

        // Horizontal bar of cross
        for xOff in stride(from: -17, through: 17, by: 4) {
            points.append(CGPoint(x: centerX + CGFloat(xOff) + CGFloat.random(in: -2...2),
                                  y: centerY - 10 + CGFloat.random(in: -3...3)))
        }

        // Extra particles scattered around cross for density
        for _ in 0..<20 {
            let isVertical = Bool.random()
            if isVertical {
                points.append(CGPoint(
                    x: centerX + CGFloat.random(in: -5...5),
                    y: centerY + CGFloat.random(in: -25...35)
                ))
            } else {
                points.append(CGPoint(
                    x: centerX + CGFloat.random(in: -17...17),
                    y: centerY - 10 + CGFloat.random(in: -5...5)
                ))
            }
        }

        return points
    }

    private func animate() {
        if reduceMotion {
            // Show bible icon and title immediately, skip particle animation
            particleOpacity = 0
            crossOpacity = 1
            bookOpacity = 1
            bookScale = 1.0
            titleOpacity = 1
            titleOffset = 0

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                finalOpacity = 0
                backgroundOpacity = 0
                onFinished()
            }
            return
        }

        // Particles converge to cross shape
        withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
            converged = true
        }

        // Cross solidifies
        withAnimation(.easeIn(duration: 0.3).delay(1.0)) {
            crossOpacity = 1
        }

        // Particles fade as bible appears
        withAnimation(.easeIn(duration: 0.3).delay(1.1)) {
            particleOpacity = 0
        }

        // Bible materializes around the cross
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.1)) {
            bookOpacity = 1
            bookScale = 1.0
        }

        // Title
        withAnimation(.easeOut(duration: 0.4).delay(1.3)) {
            titleOpacity = 1
            titleOffset = 0
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
